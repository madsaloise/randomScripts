using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;
using ReminderApp.Models;

namespace ReminderApp.Services
{
    public class ReminderStore
    {
        private readonly string _dataDir;
        private readonly string _dataFile;
        private static readonly JsonSerializerOptions JsonOptions = new()
        {
            WriteIndented = true
        };

        public ReminderStore()
        {
            _dataDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "ReminderApp");
            _dataFile = Path.Combine(_dataDir, "reminders.json");
            Directory.CreateDirectory(_dataDir);
        }

        public List<Reminder> Load()
        {
            if (!File.Exists(_dataFile)) return new List<Reminder>();
            try
            {
                var raw = File.ReadAllText(_dataFile);
                if (string.IsNullOrWhiteSpace(raw)) return new List<Reminder>();
                return JsonSerializer.Deserialize<List<Reminder>>(raw) ?? new List<Reminder>();
            }
            catch
            {
                return new List<Reminder>();
            }
        }

        public void Save(IEnumerable<Reminder> reminders)
        {
            var json = JsonSerializer.Serialize(reminders, JsonOptions);
            File.WriteAllText(_dataFile, json);
        }
    }
}
