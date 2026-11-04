using System;
using System.Globalization;
using System.Windows;

namespace ReminderApp.Views
{
    public partial class SnoozeWindow : Window
    {
        private static readonly string[] TimeFormats = { "H:mm", "HH:mm", "H", "HH" };

        public DateTime ResultDueAt { get; private set; }

        public SnoozeWindow(DateTime currentDue)
        {
            InitializeComponent();
            DpDate.SelectedDate = currentDue.Date;
            TxtTime.Text = currentDue.ToString("HH:mm");
        }

        private void BtnOk_Click(object sender, RoutedEventArgs e)
        {
            if (!string.IsNullOrWhiteSpace(TxtMinutes.Text))
            {
                if (!int.TryParse(TxtMinutes.Text, out var m) || m <= 0)
                {
                    MessageBox.Show("Minutter skal være et positivt heltal.", "Fejl",
                                    MessageBoxButton.OK, MessageBoxImage.Warning);
                    return;
                }
                ResultDueAt = DateTime.Now.AddMinutes(m);
            }
            else
            {
                if (DpDate.SelectedDate == null) return;
                if (!DateTime.TryParseExact(TxtTime.Text, TimeFormats, CultureInfo.InvariantCulture,
                                            DateTimeStyles.None, out var t))
                {
                    MessageBox.Show($"Kan ikke parse tid '{TxtTime.Text}'.", "Fejl",
                                    MessageBoxButton.OK, MessageBoxImage.Warning);
                    return;
                }
                ResultDueAt = DpDate.SelectedDate.Value.Date + t.TimeOfDay;
            }
            DialogResult = true;
            Close();
        }

        private void BtnCancel_Click(object sender, RoutedEventArgs e)
        {
            DialogResult = false;
            Close();
        }
    }
}
