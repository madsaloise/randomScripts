using System.Windows;
using ReminderApp.Models;

namespace ReminderApp.Views
{
    public enum PopupAction { None, MarkDone, Snooze15 }

    public partial class ReminderPopupWindow : Window
    {
        public PopupAction Action { get; private set; } = PopupAction.None;

        public ReminderPopupWindow(Reminder r)
        {
            InitializeComponent();
            TxtDue.Text = "Forfaldt: " + r.DueAt.ToString("yyyy-MM-dd HH:mm");
            TxtText.Text = r.Text;
            TxtNotes.Text = r.Notes;
            if (string.IsNullOrWhiteSpace(r.Notes)) TxtNotes.Visibility = Visibility.Collapsed;
        }

        private void BtnDone_Click(object sender, RoutedEventArgs e)     { Action = PopupAction.MarkDone; Close(); }
        private void BtnSnooze15_Click(object sender, RoutedEventArgs e) { Action = PopupAction.Snooze15; Close(); }
        private void BtnClose_Click(object sender, RoutedEventArgs e)    { Action = PopupAction.None;     Close(); }
    }
}
