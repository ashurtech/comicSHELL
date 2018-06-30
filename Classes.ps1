Add-Type -Path "E:\powershell\PoshComic\MahApps.Metro.dll","E:\powershell\PoshComic\System.Windows.Interactivity.dll"
#Add-Type -Path "E:\powershell\PoshComic\System.Windows.Interactivity.dll"

#region CLASSES
###############

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