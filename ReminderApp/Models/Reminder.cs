using System;

namespace ReminderApp.Models
{
    public class Reminder
    {
        public string Id { get; set; } = Guid.NewGuid().ToString();
        public string Text { get; set; } = string.Empty;
        public DateTime DueAt { get; set; }
        public string Status { get; set; } = ReminderStatus.Pending;
        public string Notes { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; } = DateTime.Now;
    }

    public static class ReminderStatus
    {
        public const string Pending = "Pending";
        public const string AwaitingOthers = "Awaiting Others";
        public const string Done = "Done";
        public const string Snoozed = "Snoozed";
    }
}
