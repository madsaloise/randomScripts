using System;

namespace ReminderApp.Models
{
    public class ReminderRow
    {
        public string Id { get; set; } = string.Empty;
        public string Text { get; set; } = string.Empty;
        public DateTime DueAt { get; set; }
        public string DueText => DueAt.ToString("yyyy-MM-dd HH:mm");
        public string Status { get; set; } = string.Empty;
        public string Notes { get; set; } = string.Empty;
        public bool Overdue { get; set; }

        public static ReminderRow From(Reminder r)
        {
            var overdue = (r.Status == ReminderStatus.Pending || r.Status == ReminderStatus.AwaitingOthers)
                          && r.DueAt <= DateTime.Now;
            return new ReminderRow
            {
                Id = r.Id,
                Text = r.Text,
                DueAt = r.DueAt,
                Status = r.Status,
                Notes = r.Notes,
                Overdue = overdue
            };
        }
    }
}
