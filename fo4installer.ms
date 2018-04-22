-- Installer script v0.4 by msi --
(
try destroyDialog fo4u_installer Catch()
rollout fo4u_installer "fo4utils Setup" width:210 height:60
(
	local oldmax = (MaxVersion())[1]<15000
	local userplugcfg = (symbolicPaths.getPathValue "$plugcfg")+"\\"
	local userscripts = (symbolicPaths.getPathValue "$userScripts")+"\\"
	local userstartupscripts = (symbolicPaths.getPathValue "$userstartupscripts")+"\\"
	local tempdir = getFilenamePath (getSourceFileName())
	
	label lbl1 "Select an option:" pos:[5,5] width:200 height:13
	button install1 "Install" pos:[5,25] width:120 height:30 toolTip:("Install to \""+userstartupscripts) across:2
	button uninstall "Uninstall" pos:[130,25] width:75 height:30

	fn delDir DirPath = (
		if doesFileExist dirPath do (
			command = "RD /S /Q \""+dirPath+"\""
			HiddenDOSCommand command startpath:".\\"
		)
	)
	fn delFile filePath = (
		if doesFileExist filePath do (
			deleteFile filePath
		)
	)
	fn copyDir sourceDir destDir = (
		command = "XCOPY \""+sourceDir+"*\" \""+destDir+"\" /Q /I /S /Y"	
		HiddenDOSCommand command startpath:".\\"
	)
	fn uninst = (
		try (UtilityPanel.CloseUtility fo4utils) catch()
		try (closeRolloutFloater fo4utilsDialog) catch()
		try (DestroyDialog fo4utilsDialog) catch()
	 
		gc()
		delDir (userscripts+"robboten")
		delFile (userplugcfg+"fo4utils.ini")
		delFile (userstartupscripts+"fo4utils.ms")
	)
	fn checkuninst = (
		if doesFileExist(userscripts+"robboten") or doesFileExist(userstartupscripts+"fo4utils.ms") then (
			if qb = queryBox ("You have the fo4utils installed.  Do you want to uninstall it first?") title: "Warning" do uninst()
			qb
		) else true	
	)	
	on fo4u_installer open do (
		if oldmax do (
			lbl1.text="Only 3dsmax 2013+ is supported!"
			install1.enabled = false
			uninstall.enabled = false 
		)
	)
	on install1 pressed do (
		if checkuninst() do ( 
			if tempdir == symbolicPaths.getPathValue "$temp"+"\\robboten\\" then (
				setWaitCursor()
				copyDir (tempdir+"scripts\\") userscripts
				copyDir (tempdir+"fo4utils.ini") userplugcfg
				sleep 1
				lbl1.text="Installed successfully."				
				try filein (userstartupscripts+"fo4utils.ms") Catch()
				try (UtilityPanel.OpenUtility fo4utils) Catch()
				msg="fo4utils was successfully installed.\n\nThe utility will be found under MAXScript utilities\n"
				msg +="You need to restart 3ds Max in order to complete the instalation.\n"
				messagebox msg title:"fo4utils"
			) else (
				messagebox "Files for installation not found" title:"fo4utils"
			)
		)
	)
	on uninstall pressed do (
		if queryBox "Are you sure?" title: "Uninstall!" do (
			lbl1.text="Started..."
			setWaitCursor()
			uninst()
			lbl1.text="Uninstalled successfully."
			messagebox "fo4utils was successfully uninstalled. \n\nPlease Restart 3ds Max." title:"fo4utils"
		)
	)
	on fo4u_installer close do (
		if tempdir == symbolicPaths.getPathValue "$temp"+"\\robboten\\" do delDir tempdir
		fo4u_installer = undefined
		gc()
	)
)
createDialog fo4u_installer style:#(#style_toolwindow, #style_border, #style_sysmenu)
)