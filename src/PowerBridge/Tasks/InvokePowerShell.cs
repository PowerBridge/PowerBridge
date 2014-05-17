﻿using System;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using Microsoft.Build.Utilities;
using PowerBridge.Internal;

namespace PowerBridge.Tasks
{
    public class InvokePowerShell : AppDomainIsolatedTask
    {
        public string Expression { get; set; }

        public override bool Execute()
        {
            Execute(Expression, new BuildTaskLog(Log));

            return !Log.HasLoggedErrors;
        }

        internal static void Execute(string expression, IBuildTaskLog taskLog)
        {
            Environment.SetEnvironmentVariable("PSExecutionPolicyPreference", "Bypass");

            using (var powerShellOutput = new PowerShellHostOutput(taskLog))
            {
                var host = new PowerShellHost(powerShellOutput);
                using (var runspace = RunspaceFactory.CreateRunspace(host))
                using (var powerShell = PowerShell.Create())
                {
                    powerShell.Runspace = runspace;
                    powerShell.Streams.Error.DataAdded += (sender, args) =>
                    {
                        powerShellOutput.WriteError(powerShell.Streams.Error[args.Index]);
                    };

                    runspace.Open();
                    powerShell.AddScript(expression);

                    try
                    {
                        powerShell.Invoke();
                    }
                    catch (RuntimeException e)
                    {
                        if (e.ErrorRecord == null)
                        {
                            throw;
                        }

                        powerShellOutput.WriteError(e.ErrorRecord);
                    }
                }                
            }            
        }
    }
}
