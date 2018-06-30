using namespace System.Windows.Forms;
using namespace System.ComponentModel;
using namespace System.Data;
using namespace System.Drawing;
using namespace presentationframework;
using namespace PresentationCore;
using namespace System.Windows.Forms;
try
{
   Add-Type -Path "E:\powershell\PoshComic\assembly\MahApps.Metro.dll"
   Add-Type -Path "E:\powershell\PoshComic\assembly\System.Windows.Interactivity.dll"
}
catch [System.Reflection.ReflectionTypeLoadException]
{
   Write-Host "Message: $($_.Exception.Message)"
   Write-Host "StackTrace: $($_.Exception.StackTrace)"
   Write-Host "LoaderExceptions: $($_.Exception.LoaderExceptions)"
}
. "$PSScriptRoot\classes.ps1"


Class comicshell {
#region properties
[string]$librarySearchDir;
[hashtable]$Global:ComicSyncHash;

#endregion

#region constructors
comicshell ([string]$searchdir){



}
#endregion

#region methods
prep () {}
drawMain () {}
drawSeries () {}
drawIssue () {}
#endregion
}