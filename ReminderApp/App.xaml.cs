using System;
using System.Threading;
using System.Windows;

namespace ReminderApp
{
    public partial class App : System.Windows.Application
    {
        private const string MutexName = "Global\\ReminderApp.SingleInstance.9F3D7B2A";
        private Mutex? _singleInstanceMutex;

        protected override void OnStartup(StartupEventArgs e)
        {
            _singleInstanceMutex = new Mutex(true, MutexName, out var createdNew);
            if (!createdNew)
            {
                MessageBox.Show("ReminderApp kører allerede.", "ReminderApp",
                                MessageBoxButton.OK, MessageBoxImage.Information);
                Shutdown();
                return;
            }
            ShutdownMode = ShutdownMode.OnExplicitShutdown;
            base.OnStartup(e);
        }

        protected override void OnExit(ExitEventArgs e)
        {
            try { _singleInstanceMutex?.ReleaseMutex(); } catch { }
            _singleInstanceMutex?.Dispose();
            base.OnExit(e);
        }
    }
}
