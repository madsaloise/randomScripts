using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Drawing;
using System.Linq;
using System.Windows;
using System.Windows.Threading;
using ReminderApp.Models;
using ReminderApp.Services;
using ReminderApp.Views;
using WinForms = System.Windows.Forms;

namespace ReminderApp
{
    public partial class MainWindow : Window
    {
        private readonly ReminderStore _store = new();
        private List<Reminder> _reminders = new();
        private readonly DispatcherTimer _focusTimer;
        private readonly DispatcherTimer _refreshTimer;
        // Tracks the DueAt value we've already popped a notification for, keyed by reminder Id.
        private readonly Dictionary<string, DateTime> _notified = new();
        private WinForms.NotifyIcon? _tray;
        private bool _exiting;

        public MainWindow()
        {
            InitializeComponent();
            _reminders = _store.Load();

            InitTrayIcon();

            _focusTimer = new DispatcherTimer { Interval = TimeSpan.FromMinutes(15) };
            _focusTimer.Tick += FocusTimer_Tick;
            _focusTimer.Start();

            _refreshTimer = new DispatcherTimer { Interval = TimeSpan.FromSeconds(30) };
            _refreshTimer.Tick += (_, _) => { CheckDueNotifications(); RefreshGrid(); };
            _refreshTimer.Start();

            Loaded += (_, _) => CheckDueNotifications();

            Closed += (_, _) => { _focusTimer.Stop(); _refreshTimer.Stop(); };

            RefreshGrid();
        }

        private void InitTrayIcon()
        {
            var menu = new WinForms.ContextMenuStrip();
            menu.Items.Add("Vis", null, (_, _) => ShowFromTray());
            menu.Items.Add("Afslut", null, (_, _) => ExitApp());

            _tray = new WinForms.NotifyIcon
            {
                Icon = LoadAppIcon(),
                Text = "ReminderApp",
                Visible = true,
                ContextMenuStrip = menu
            };
            _tray.DoubleClick += (_, _) => ShowFromTray();
        }

        private static Icon LoadAppIcon()
        {
            try
            {
                var uri = new Uri("pack://application:,,,/app.ico", UriKind.Absolute);
                using var stream = Application.GetResourceStream(uri).Stream;
                return new Icon(stream);
            }
            catch
            {
                return SystemIcons.Application;
            }
        }

        private void ShowFromTray()
        {
            Show();
            if (WindowState == WindowState.Minimized) WindowState = WindowState.Normal;
            Activate();
            Focus();
        }

        private void ExitApp()
        {
            _exiting = true;
            if (_tray != null) { _tray.Visible = false; _tray.Dispose(); _tray = null; }
            Application.Current.Shutdown();
        }

        protected override void OnClosing(CancelEventArgs e)
        {
            if (!_exiting)
            {
                e.Cancel = true;
                Hide();
                return;
            }
            base.OnClosing(e);
        }

        private void RefreshGrid()
        {
            var showDone = ChkShowDone.IsChecked == true;
            var rows = _reminders
                .Where(r => showDone || r.Status != ReminderStatus.Done)
                .Select(ReminderRow.From)
                .OrderByDescending(r => r.Overdue)
                .ThenBy(r => r.DueAt)
                .ToList();
            Grid.ItemsSource = rows;

            var overdue = rows.Count(r => r.Overdue);
            var pending = _reminders.Count(r => r.Status == ReminderStatus.Pending
                                             || r.Status == ReminderStatus.AwaitingOthers);
            TxtStatus.Text = $"Reminders: {_reminders.Count} | Åbne: {pending} | Forfaldne: {overdue}";
        }

        private Reminder? GetSelected()
        {
            if (Grid.SelectedItem is not ReminderRow row) return null;
            return _reminders.FirstOrDefault(r => r.Id == row.Id);
        }

        private void SaveAndRefresh()
        {
            _store.Save(_reminders);
            RefreshGrid();
        }

        private void SetStatus(string status)
        {
            var r = GetSelected();
            if (r == null) return;
            r.Status = status;
            SaveAndRefresh();
        }

        private void SetDue(DateTime due)
        {
            var r = GetSelected();
            if (r == null) return;
            SetDue(r, due);
        }

        private void SetDue(Reminder r, DateTime due)
        {
            r.DueAt = due;
            if (r.Status == ReminderStatus.Done) r.Status = ReminderStatus.Pending;
            _notified.Remove(r.Id);
            SaveAndRefresh();
        }

        private void CheckDueNotifications()
        {
            var now = DateTime.Now;
            foreach (var r in _reminders.ToList())
            {
                if (r.Status != ReminderStatus.Pending && r.Status != ReminderStatus.AwaitingOthers) continue;
                if (r.DueAt > now) continue;
                if (_notified.TryGetValue(r.Id, out var last) && last == r.DueAt) continue;

                _notified[r.Id] = r.DueAt;
                ShowReminderPopup(r);
            }
        }

        private void ShowReminderPopup(Reminder r)
        {
            var popup = new ReminderPopupWindow(r);
            popup.Show();
            popup.Closed += (_, _) =>
            {
                switch (popup.Action)
                {
                    case PopupAction.MarkDone:
                        r.Status = ReminderStatus.Done;
                        SaveAndRefresh();
                        break;
                    case PopupAction.Snooze15:
                        SetDue(r, DateTime.Now.AddMinutes(15));
                        break;
                }
            };
        }

        private void BtnNew_Click(object sender, RoutedEventArgs e)
        {
            var dlg = new EditorWindow { Owner = this };
            if (dlg.ShowDialog() == true)
            {
                _reminders.Add(new Reminder
                {
                    Text = dlg.ResultText,
                    DueAt = dlg.ResultDueAt,
                    Notes = dlg.ResultNotes
                });
                SaveAndRefresh();
            }
        }

        private void BtnEdit_Click(object sender, RoutedEventArgs e)
        {
            var r = GetSelected();
            if (r == null) return;
            var dlg = new EditorWindow(r) { Owner = this };
            if (dlg.ShowDialog() == true)
            {
                r.Text = dlg.ResultText;
                r.DueAt = dlg.ResultDueAt;
                r.Notes = dlg.ResultNotes;
                SaveAndRefresh();
            }
        }

        private void BtnDone_Click(object sender, RoutedEventArgs e)   => SetStatus(ReminderStatus.Done);
        private void BtnAwait_Click(object sender, RoutedEventArgs e)  => SetStatus(ReminderStatus.AwaitingOthers);
        private void BtnReopen_Click(object sender, RoutedEventArgs e) => SetStatus(ReminderStatus.Pending);

        private void BtnSnooze15_Click(object sender, RoutedEventArgs e) => SetDue(DateTime.Now.AddMinutes(15));
        private void BtnSnooze1h_Click(object sender, RoutedEventArgs e) => SetDue(DateTime.Now.AddHours(1));
        private void BtnSnoozeTom_Click(object sender, RoutedEventArgs e)
            => SetDue(DateTime.Today.AddDays(1).AddHours(10));

        private void BtnSnoozeCustom_Click(object sender, RoutedEventArgs e)
        {
            var r = GetSelected();
            if (r == null) return;
            var dlg = new SnoozeWindow(r.DueAt) { Owner = this };
            if (dlg.ShowDialog() == true) SetDue(dlg.ResultDueAt);
        }

        private void BtnDelete_Click(object sender, RoutedEventArgs e)
        {
            var r = GetSelected();
            if (r == null) return;
            var ans = MessageBox.Show($"Slet reminder '{r.Text}'?", "Bekræft",
                                      MessageBoxButton.YesNo, MessageBoxImage.Question);
            if (ans == MessageBoxResult.Yes)
            {
                _reminders.Remove(r);
                SaveAndRefresh();
            }
        }

        private void ChkShowDone_Changed(object sender, RoutedEventArgs e) => RefreshGrid();

        private void Grid_MouseDoubleClick(object sender, System.Windows.Input.MouseButtonEventArgs e)
            => BtnEdit_Click(sender, e);

        private void FocusTimer_Tick(object? sender, EventArgs e)
        {
            var hasOverdue = _reminders.Any(r =>
                (r.Status == ReminderStatus.Pending || r.Status == ReminderStatus.AwaitingOthers)
                && r.DueAt <= DateTime.Now);
            RefreshGrid();
            if (!hasOverdue) return;

            if (WindowState == WindowState.Minimized) WindowState = WindowState.Normal;
            Show();
            Topmost = true;
            Activate();
            Topmost = false;
            Focus();
        }
    }
}