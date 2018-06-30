using namespace System.Windows.Forms;
using namespace System.ComponentModel;
using namespace System.Data;
using namespace System.Drawing;
using namespace presentationframework;
using namespace PresentationCore;
using namespace System.Windows.Forms;
$VerbosePreference = 2; ######FOR NOW
try
{
   Add-Type -Path (Join-Path $PSScriptRoot "MahApps.Metro.dll")
   Add-Type -Path (Join-Path $PSScriptRoot "System.Windows.Interactivity.dll")
}
catch [System.Reflection.ReflectionTypeLoadException]
{
   Write-Host "Message: $($_.Exception.Message)"
   Write-Host "StackTrace: $($_.Exception.StackTrace)"
   Write-Host "LoaderExceptions: $($_.Exception.LoaderExceptions)"
}
. "$PSScriptRoot\classes.ps1"
function LoadXml ($global:filename)
{
    $XamlLoader=(New-Object System.Xml.XmlDocument)
    $XamlLoader.Load($filename)
    return $XamlLoader
}

Class comicshell {
#region properties
[string]$librarySearchDir = "\\FREENAS\Vault\Comics\"; ####HARDCODE FOR NOW
[array]$foundcomics;
[hashtable]$ComicSyncHash;
[hashtable]$appImages
[System.Windows.Controls.ContentPresenter]$contentPresenter
[hashtable]$hashComicSeries
[System.Collections.ArrayList]$listcomicseries
#endregion

#region constructors
comicshell (){
$this.prep()
$this.getAppImages()
$this.loadComicsInfo()
$this.drawMain()


}
#endregion

#region methods
[System.Xml.XmlDocument] loadXML ([string]$path){$XmlLoader=(New-Object System.Xml.XmlDocument);$XmlLoader.Load($path);return $XmlLoader}
prep () {
$this.ComicSyncHash = [hashtable]::Synchronized(@{});
$this.appImages = @{}
$this.hashComicSeries = @{}
$this.listComicSeries = @()
}
getAppImages () {  #########Find images for GUI
Write-Verbose "getAppImages: finding images in $("$PSScriptRoot\Images")"
(Get-ChildItem -Path "$PSScriptRoot\Images" -Recurse -Force).`
foreach({`
Write-Verbose "getAppImages: adding $($_.fullname)"
$this.appImages.add($_.name,$_.fullname)})
}
loadComicsInfo () {
Write-verbose "loadComicsInfo: Searching for comics in $($this.librarySearchDir)";
$this.foundcomics = (GCI -Path $this.librarySearchDir -Directory).`
where({($_.getFiles()).extension -contains '.cbr' -or ($_.getFiles()).extension -contains '.cbz'})
Write-verbose "loadComicsInfo: found $(($this.foundcomics).count) comics"
}
#region method-drawMAIN
drawMain () {
####BASE xaml
$newTile = [ComicTile]::new();
$Xaml_0= loadXML("$PSSCRIPTROOT\ComicSHELL_Base.xaml")
$xmlNodeReader_0=(New-Object System.Xml.XmlNodeReader $Xaml_0)
$this.ComicSyncHash['Form'] = [Windows.Markup.XamlReader]::Load($xmlNodeReader_0)
#region method-DrawMAIN-controls
#####Controls
$mainGrid = $this.ComicSyncHash['Form'].FindName("maingrid")
$mainGrid.HorizontalAlignment = "Stretch"
$mainGrid.VerticalAlignment = "Stretch"
##################CONTENT PRESENTER
$this.contentPresenter = [System.Windows.Controls.ContentPresenter]::new()
$this.contentPresenter.Name = "contactPres"
$contentGrid = [System.Windows.Controls.Grid]::new()
$mainGrid.AddChild($this.contentPresenter)
$gridCol0 = [System.Windows.Controls.ColumnDefinition]::new()
$gridCol1 = [System.Windows.Controls.ColumnDefinition]::new()
$gridCol2 = [System.Windows.Controls.ColumnDefinition]::new()
$gridCol0.Width="Auto"
$gridCol1.Width="*"
$gridCol2.Width="Auto"
$contentGrid.ColumnDefinitions.Clear()
$contentGrid.ColumnDefinitions.Add($gridCol0)
$contentGrid.ColumnDefinitions.Add($gridCol1)
$contentGrid.ColumnDefinitions.Add($gridCol2)
$gridRow0 = [System.Windows.Controls.RowDefinition]::new()
$gridRow1 = [System.Windows.Controls.RowDefinition]::new()
$gridRow2 = [System.Windows.Controls.RowDefinition]::new()
$gridRow0.Height="Auto"
$gridRow1.Height="*"
$gridRow2.Height="100"
$contentGrid.RowDefinitions.Clear()
$contentGrid.RowDefinitions.Add($gridRow0)
$contentGrid.RowDefinitions.Add($gridRow1)
##########################################################
#######TextBlock
$allSeriesTextBlock = [System.Windows.Controls.TextBlock]::new()
$allSeriesTextBlock.Name = "TextHeader"
$allSeriesTextBlock.VerticalAlignment = "Top"
$allSeriesTextBlock.Text = "All Comics"
$allSeriesTextBlock.Foreground = "White"
$allSeriesTextBlock.FontSize = 35
[System.Windows.Controls.Grid]::SetColumn($allSeriesTextBlock,1)
[System.Windows.Controls.Grid]::SetRow($allSeriesTextBlock,0)
$contentGrid.AddChild($allSeriesTextBlock);

##############WrapPanel
$Global:allSeriesWrapPanel = [System.Windows.Controls.WrapPanel]::new()
$Global:allSeriesWrapPanel.Name="TilePanel"
$Global:allSeriesWrapPanel.HorizontalAlignment="Center"
$Global:allSeriesWrapPanel.VerticalAlignment="Top"
$Global:allSeriesWrapPanel.Margin="15"
#endregion
$this.foundComics.foreach({`
Write-Verbose "method-drawMAIN-makingtiles: $($_.fullname)"
$thisSeries = $_;
$thisSeries = ([ComicSeries]::new($thisSeries.fullname));
$this.hashComicSeries.add(($thisSeries.SeriesGUId),$thisSeries);
$this.listComicSeries.add($thisSeries);
$newTile = [ComicTile]::new();
$newTile.Title = $thisSeries.SeriesTitle;
$newtile.seriesGUID = $thisSeries.SeriesGUId;
$newTile.Height = 240;
$newTile.Width = 160;
$newTile.Tooltip = $thisSeries.SeriesTitle;
try
{
$newImageBrush = [System.Windows.Media.ImageBrush]::new($thisSeries.CoverImagePath);
}
catch
{
Write-Verbose "method-drawMAIN-Addtiles: No Valid Cover Image for $($thisseries)"
$newImageBrush = [System.Windows.Media.ImageBrush]::new($this.appImages['pattern.png']);
}
finally
{
$newTile.Background = $newImageBrush;
}
###CLICK
$newTile.Add_Click({
$sender = $args[0]
$e      = $args[1]
[string]$thisSeriesguid = $sender.seriesGUID
Write-verbose "Series Clicked - $($title)"
$Global:selectedSeries =  $this.hashComicSeries[([string]$thisSeriesguid)]
Write-Verbose "Title: $($selectedSeries.SeriesTitle)"
Write-Verbose "Year: $([string]$selectedSeries.year)"
$Global:fromList = ($this.listComicSeries).where({$_.SeriesGUID -eq $thisSeriesguid})
Write-Verbose "List - Title: $($fromList.SeriesTitle)"
Write-Verbose "List - Year: $($fromList.Year)"
Write-Verbose "List - coverimage: $($fromList.CoverImagePath)"}) ###END CLICK
#$global:SeriesTiles += $newTile;
$Global:allSeriesWrapPanel.AddChild($newtile);
})
#######ScrollViewer
Write-Verbose "method-drawMAIN-SettingupScrollViewer"
$scrollviewer = [System.Windows.Controls.ScrollViewer]::new()
(($scrollviewer.Content.Children.Height)|Measure-Object -Sum).sum
$scrollviewer.HorizontalScrollBarVisibility="Disabled";
$scrollviewer.VerticalScrollBarVisibility = "Visible";
$scrollviewer.HorizontalAlignment="Center";
[System.Windows.Controls.Grid]::SetColumn($scrollviewer,1)
[System.Windows.Controls.Grid]::SetRow($scrollviewer,1)
#$scrollviewer.AddChild($allSeriesWrapPanel);
$scrollviewer.Content = $Global:allSeriesWrapPanel
#$scrollviewer.UpdateLayout()
Write-Verbose "method-drawMAIN: drawing GUI"
$contentGrid.AddChild($scrollviewer);
$this.contentPresenter.content = $contentGrid
if($this.ComicSyncHash['Form'].Visibility -ne 'Visible'){$this.ComicSyncHash['Form'].ShowDialog()}

}#endregion
drawSeries () {}
prepareIssue () {}
drawIssue () {}
#endregion
}

#########################
#region CLASS_ComicIssue
#########################
Class ComicIssue {
[string]$SeriesTitle
[string]$SeriesGUID
[string]$IssueGUID
[int]$IssueNumber
[string]$IssuePath
[regex]$comicIssueRegex = [regex]'(?<title>[\w|\s]+) (?<issuenumber>\d+)\s\((?<year>\d{4})\).(?<format>\w{3})'
[string]$fileFormat
##Constructor
##using path and guid
ComicIssue () {}
ComicIssue ([string]$IssuePath,[string]$SeriesGUID){`
$this.SeriesGUID = $SeriesGUID;
$this.IssueGUID = ([guid]::NewGuid()).guid;
$this.IssuePath = $IssuePath;
if((get-item -Path $IssuePath).name -match $this.comicIssueRegex){`
$this.SeriesTitle = $matches.title;
$this.IssueNumber = [int]($matches.issuenumber);
$this.fileFormat = $matches.format}
}
#lots of props
ComicIssue ([string]$SeriesTitle,[string]$SeriesGUID,[string]$IssuePath) {$this.SeriesTitle = $SeriesTitle;$this.SeriesGUID = $SeriesGUID;$this.IssueGUID = ([string]::NewGuid()).guid;$this.IssuePath = $IssuePath}
#########METHODS
[ComicTile] ShowIssueTile () {`
$tileOUT = [ComicTile]::new();
$tileOUT.Title = "$($this.SeriesTitle) - $($this.IssueNumber)" ;
$tileOUT.Height = 120;
$tileOUT.Width = 80;
$tileOUT.Tooltip = "$($this.SeriesTitle) - $($this.IssueNumber)";
return $tileOUT
}
#ENDCLASS
}
#endregion
##########################
#region CLASS_ComicSeries
##########################
Class ComicSeries {
[string]$SeriesTitle
[string]$SeriesPath
[string]$CoverImagePath
$SeriesGUID
[ComicIssue[]]$collIssues
[int]$year
[regex]$ComicSeriesRegex = [regex]'(?<title>[\w|\s\-]+) \((?<year>\d{4})\)'
[int]$Height
[int]$Width
$Tooltip

##Constructor
ComicSeries () {}
ComicSeries ([string]$SeriesPath){`
$this.SeriesPath = $SeriesPath;
if($SeriesPath -match $this.ComicSeriesRegex){`
$this.SeriesTitle = $matches.title;
$this.year = [int]($matches.year)}
else{Write-Error -Message "Parse title failed"}
$this.SeriesGUID = ([guid]::NewGuid()).guid;
$this.CoverImagePath = (GCI -Path $this.SeriesPath -Filter 'cover.jpg').fullname
$this.GetComics($this.SeriesPath)
}
ComicSeries ([string]$SeriesTitle,[string]$SeriesPath,[string]$CoverImagePath) {$this.SeriesTitle = $SeriesTitle;$this.SeriesPath = $SeriesPath;$this.CoverImagePath = $CoverImagePath;$this.SeriesGUID = ([guid]::NewGuid()).guid}
##methods
GetComics ([string]$SeriesPath = $this.SeriesPath){`
$comicfiles = (GCI -Path $SeriesPath -Recurse -File).where({$_.extension -eq '.cbr' -or $_.extension -eq '.cbz'});
Write-Verbose "Found :$($comicfiles.count)";
($comicfiles).foreach({Write-Verbose "Adding $($_.name)"
$this.collIssues += ([ComicIssue]::new([string]$_.fullname,[guid]$this.SeriesGUID))})
}
#region uselessandsilly
[System.Windows.Controls.Primitives.Popup] ShowSeriesTooltip(){`
$popper = [System.Windows.Controls.Primitives.Popup]::new()
$popper.PopupAnimation = "Fade"
$popper.Placement = "mouse"
$popper.AllowsTransparency = "True"
$popper.StaysOpen = "False"
$popper.Height = 300;
$popper.Width = 400;
$seriesStackPanel = [System.Windows.Controls.StackPanel]::new();
$popper.AddChild($seriesStackPanel);
$seriesStackPanel.Orientation = "Horizontal";
$seriesImage = [System.Windows.Controls.Image]::new();
$seriesImage.Source = $this.CoverImagePath;
$seriesStackPanel.AddChild($seriesImage);
$issueWrappanel = [System.Windows.Controls.WrapPanel]::new()
$seriesStackPanel.AddChild($issueWrappanel);
$textblock = [System.Windows.Controls.TextBlock]::new();
$textblock.Text = "SERIES: $($this.SeriesTitle) - YEAR: $($this.year)"
$issueWrappanel.AddChild($textblock)
($this.collIssues).foreach({$issuetile = $_.ShowIssueTile();$issueWrappanel.AddChild($issuetile)})
$popper.IsOpen = $true;
return $popper
}
#endregion
}#ENDCLASS
#region CLASS_ComicTile
#######################
Class ComicTile : MahApps.Metro.Controls.Tile {
[string]$Seriesguid
[string]$Issueguid
}
#endregion
#endregion
[ComicIssue]::new()
[ComicSeries]::new()
[ComicTile]::new()