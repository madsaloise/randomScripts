using System;
using System.Globalization;
using System.Windows;
using ReminderApp.Models;

namespace ReminderApp.Views
{
    public partial class EditorWindow : Window
    {
        private static readonly string[] TimeFormats = { "H:mm", "HH:mm", "H", "HH" };

        public string ResultText { get; private set; } = string.Empty;
        public DateTime ResultDueAt { get; private set; }
        public string ResultNotes { get; private set; } = string.Empty;

        public EditorWindow(Reminder? existing = null)
        {
            InitializeComponent();
            if (existing != null)
            {
                TxtText.Text = existing.Text;
                DpDate.SelectedDate = existing.DueAt.Date;
                TxtTime.Text = existing.DueAt.ToString("HH:mm");
                TxtNotes.Text = existing.Notes;
                Title = "Rediger reminder";
            }
            else
            {
                DpDate.SelectedDate = DateTime.Today;
                TxtTime.Text = DateTime.Now.AddMinutes(30).ToString("HH:mm");
                Title = "Ny reminder";
            }
        }

        private void BtnOk_Click(object sender, RoutedEventArgs e)
        {
            if (string.IsNullOrWhiteSpace(TxtText.Text))
            {
                MessageBox.Show("Tekst er påkrævet.", "Fejl", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }
            if (DpDate.SelectedDate == null)
            {
                MessageBox.Show("Vælg en dato.", "Fejl", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }
            if (!DateTime.TryParseExact(TxtTime.Text, TimeFormats, CultureInfo.InvariantCulture,
                                        DateTimeStyles.None, out var t))
            {
                MessageBox.Show($"Kan ikke parse tid '{TxtTime.Text}'. Brug HH:mm.", "Fejl",
                                MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            ResultText = TxtText.Text.Trim();
            ResultDueAt = DpDate.SelectedDate.Value.Date + t.TimeOfDay;
            ResultNotes = TxtNotes.Text ?? string.Empty;
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
