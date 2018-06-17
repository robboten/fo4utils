macroScript fo4utilsM
category:"Toolbox"
internalCategory:"Toolbox"
toolTip:"FO4Utils"
(

Global fo4utilsDialog

local vers=("version " + 0.43 as string)

local shadertype=1
local snapPosCheck=off
local iniFolder= ((getDir #plugcfg) + "\\fo4utils.ini")
local theKeys=(getINISetting iniFolder "Snaps")
local theSnaps=for o in theKeys collect getIniSetting iniFolder "Snaps" o
local SnapNode_BASE_NAME = "WorkshopConnectPoints"

include "$userScripts\\robboten\\maxcrc.mse"

	--testing stuff
fn tester=(
		 --print (getExportHistory())

		--print BSHavokMaterialTypes
		--print GetINISetting (("Directories" "Scenes")
	--smat = Standard()
	--mat=BSEffectFX()
	--mat=BSLightingFX()
	--mat=$.material

	--for p in getPropNames mat.maps[5] do format "% = %\n" p (getProperty mat.maps[5] p)
	--showProperties mat

	--print (getFilenameType mat.filename)
	--	print "----------------------------------------"

	--for p in getPropNames mat.delegate do format "% = %\n" p (getProperty mat.delegate p)
	--for p in getPropNames mat do format "% = %\n" p (getProperty mat p)

	--with printAllElements on (print (getpropnames(mat)) #nomap;ok)
	--print (getpropnames mat[#maps])
)


-- Helper functions (from Bethesdas/Gamebryos files)
--------------------------------------------------------------------------------------
function GetIndex array item =
(
	local index = 1
	for obj in array do
	(
		if obj == item then
			return index
		else
			index = index + 1
	)
	return undefined
)

function GetRootsFromSelection =
(
	local SelectedRoots = #()
	for obj in selection do -- values for each selected object
	(
		local bFound = false
		while obj.parent != undefined do obj = obj.parent
		for root in SelectedRoots do
		(
			if root == obj then bFound = true
		)

		if bFound == false then append SelectedRoots obj
	)
	return SelectedRoots
)

function IsSnapNodeRoot root =
(
	if root == undefined then return false
	local SnapNodeGroup = GetUserProp root SnapNode_BASE_NAME
	if SnapNodeGroup != true then return false else return true
)

------------------------  Mat conversion ----------------------------------------------------------------
rollout ConvertRollout "Convert Imported Materials"
(
	radiobuttons Shader_Type "" labels:#("BSBlinn", "BSLightingFX", "Standard (Figment)") columns:1 tooltip:"BSEffectShader is automatically chosen"
	button btn_cnvS "Convert Selection" width:128
	button btn_cnvA "Convert All" width:128

	-- Converts the file path of a material file to the relative path
	-- Returns undefined if "Data\Materials" is not a part of the path
	fn getRelativeMatPath asFilePath =
	(
		local srelPath = asFilePath
		if asFilePath != undefined and asFilePath != "" then
		(
			-- find Data\Materials and then trim off the data part
			local iindex = (findString asFilePath @"Data\Materials\")
			if iindex != undefined then
			(
				-- trim from 5 past the found location to the end of the string
				-- (yes, no space between - and 1 is important)
				srelPath = substring asFilePath (iindex + 5) -1
			)
		)
		srelPath
	)

	--convert BSBlinn to Standard
	fn BSBlinnTostandard objMat =
		(
		--get old and make new
		local oldMat=objMat
		local newMat = standardMaterial()
		newMat.shaderType = 2
		--copy material file
		newMat.fileName=oldMat.TargetMaterialFile
		--name as material file
		newMat.name = getFilenameFile newMat.fileName

		--add bitmaps
		newMat.specularColor = oldMat[#Standard].specular
		newMat.maps[1]= oldMat[#Standard].diffuseMap
		newMat.maps[2] = oldMat[#Standard].bumpMap
		newMat.maps[3] = oldMat[#Standard].maps[4]

		--assign material and show texture in viewport
		objMat = newMat
		showTextureMap objMat on

		return newMat
	)

	--convert to BSBlinn
	fn standardToBSBlinn objMat =
		(
		--get old and make new
		local oldMat=objMat
		local newMat = BSBlinn()
		--copy material file
		newMat.TargetMaterialFile=oldMat.fileName
		--name as material file
		newMat.name = getFilenameFile newMat.TargetMaterialFile

		--add bitmaps
		newMat.delegate.diffuseMap = oldMat.maps[1]
		newMat[#Standard].specular = oldMat.specularColor
		newMat[#Standard].bumpMap = oldMat.maps[2]
		newMat[#Standard].maps[4] = oldMat.maps[3]

		--assign material and show texture in viewport
		objMat = newMat
		showTextureMap objMat on

		return newMat
	)

	--not used atm..
	fn MakeFakeBitmap mapFile = (
		mapPath=mapFile.filename
		if (((dotnetclass "System.IO.Directory").exists mapPath) and (isDirectoryWriteable getFilenamePath mapPath))  then (
			tmpDir=getFilenamePath mapPath
		) else (
			tmpDir=(GetDir #temp+"\\")
		)
		print "Making a temp bitmap for missing file in dir "+tmpDir
		nFileName=(tmpDir + "apa.bmp")
		nBitmap=bitmap 96 96 fileName:nFileName color:black
		save nBitmap
		return nBitmap
	)

	-- standard to BSLightingFX
	fn standardToBSLFx oldMat =
	(
		--get old material and make a new BSLFX
		newMat = BSLightingFX()

		-------Add bitmaps----------
		--diffuse
		if ((oldMat.mapEnables[1]) and (doesFileExist oldMat.diffuseMap.filename)) then (
			setproperty newMat.delegate "diffuseTexture" oldMat.diffuseMap.bitmap
			--newMat.delegate.diffuseTexture = (openBitmap (oldMat.maps[1].filename))
			newMat.DiffuseEnableParam = on
		) else (
			if queryBox "No diffuse map texture found, this will make a material with no maps. Do you want to continue?" title:"Missing dds" then (
				newMat.ShowTextureParam = off
			)
			else (
				return oldMat
			)
		)
		--normal
		if ((oldMat.mapEnables[2]) and (doesFileExist oldMat.maps[2].normal_map.filename)) then (
			--newMat.delegate.normalTexture = (openBitmap (oldMat.maps[2].normal_map.filename))
			setproperty newMat.delegate "normalTexture" oldMat.maps[2].normal_map.bitmap
			newMat.NormalEnableParam = on
		)
		--smooth/spec
		if ((oldMat.mapEnables[3]) and (doesFileExist oldMat.Detail.filename)) then (
			--newMat.delegate.smoothspecmaskTexture = (openBitmap (oldMat.maps[3].filename))
			setproperty newMat.delegate "smoothspecmaskTexture" oldMat.Detail.bitmap
			newMat.SmoothSpecEnableParam = on
		)
		--greyscale/palette
		if ((oldMat.mapEnables[4]) and (doesFileExist oldMat.maps[4].filename)) then (
			--newMat.delegate.heightTexture = (openBitmap (oldMat.maps[4].filename))
			setproperty newMat.delegate "heightTexture" oldMat.maps[4].bitmap
			newMat.GrayscaleTexEnableParam = on
		)
		--Envmap
		if ((oldMat.mapEnables[5]) and (doesFileExist oldMat.Environment.filename)) then (
			--newMat.delegate.envTexture = (openBitmap (oldMat.maps[5].filename))
			setproperty newMat.delegate "envTexture" oldMat.Environment.bitmap
			newMat.EnvmapEnableParam  = on
		)
		--Glow
		if ((oldMat.mapEnables[6]) and (doesFileExist oldMat.Glow.filename)) then (
			--newMat.delegate.glowTexture = (openBitmap (oldMat.maps[6].filename))
			setproperty newMat.delegate "glowTexture" oldMat.Glow.bitmap
			newMat.GlowEnableParam = on
		)
		--innerLayer oldMat.maps[6]  Obsolete?

		--wrinkle
		if ((oldMat.mapEnables[8]) and (doesFileExist oldMat.Wrinkles.filename)) then (
			--newMat.delegate.wrinklesTexture = (openBitmap (oldMat.maps[8].filename))
			setproperty newMat.delegate "wrinklesTexture" oldMat.Wrinkles.bitmap
			newMat.WrinkleEnableParam = on
		)
		newMat.AlphaParam=oldMat.alphaTest
		newMat.AlphaValueParam=oldMat.alpha

		newMat.AlphaRefParam=oldMat.alphaTestRef
		newMat.EditorAlphaTestRef=oldMat.enableEditorAlphaRef
		newMat.ZTestParam=oldMat.zBufferTest
		newMat.ZWriteParam=oldMat.zBufferWrite
		newMat.SubSurfaceLightingParam=oldMat.subsurfaceLighting
		newMat.SubSurfaceRolloffParam=oldMat.subsurfaceLightingRolloff
		newMat.BackLightingPowerParam=oldMat.backLightPower

		newMat.SpecularParam=oldMat.specularEnabled
		newMat.SpecularColorParam=oldMat.specularColor
		newMat.SmoothnessParam=oldMat.smoothness
		newMat.SpecularScaleParam=oldMat.specularMult

		newMat.ShowEmitParam=oldMat.emitEnabled
		newMat.EmitScaleParam=oldMat.emittanceMult
		newMat.EmitColorParam=oldMat.emittanceColor

		newMat.AnisoLightingParam=oldMat.anisoLighting
		newMat.ApplyGlowmapToEmitParam=oldMat.glowmap
		newMat.RefractionParam=oldMat.refraction
		newMat.RefractionPowerParam=oldMat.refractionPower
		newMat.RefractionFireParam=oldMat.refractionFalloff
		newMat.HairParam=oldMat.hair
		newMat.HairColorParam=oldMat.hairTintColor
		newMat.EnvmapParam=oldMat.EnvironmentEnable
		newMat.EnvmapScaleParam=oldMat.environmentMappingMaskScale
		newMat.EnvmapEyeParam=oldMat.environmentMappingEye
		newMat.EnvmapWindowParam=oldMat.environmentMappingWindow
		newMat.EnvmapLightFadeParam=oldMat.applyReflectionDimming
		newMat.TreeParam=oldMat.tree
		newMat.GrayscaleColorParam=oldMat.grayscaleToPaletteColor
		newMat.GrayscaleColorScaleParam=oldMat.grayscaleToPaletteScale
		newMat.TwoSidedParam=oldMat.twoSided
		newMat.ModelSpaceNormalParam=oldMat.modelSpaceNormals
		newMat.DecalParam=oldMat.decal
		newMat.DecalNoFadeParam=oldMat.decalNoFade
		newMat.ExternalEmittanceParam=oldMat.externalEmittance
		newMat.HideSecretParam=oldMat.hideSecret
		newMat.CastShadowsParam=oldMat.castShadows
		newMat.DissolveFadeParam=oldMat.dissolveFade
		newMat.ScreenSpaceReflectionsParam=oldMat.screenSpaceReflections
		newMat.NonOccluderParam=oldMat.nonOccluder
		newMat.UTilingParam=oldMat.tileU
		newMat.VTilingParam=oldMat.tileV
		newMat.UOffsetParam=oldMat.uOffset
		newMat.VOffsetParam=oldMat.vOffset
		newMat.UScaleParam=oldMat.uScale
		newMat.VScaleParam=oldMat.vScale

		-- old mat has blendstate checkbox, new doesn't. So set to none if box is unchecked
		if oldMat.blendState==off then
			newMat.AlphaBlendParam=4
		else (
			newMat.AlphaBlendParam = case oldMat.alphaBlendMode of
			(
				4: 3 -- multiplicative
				3: 2 -- additive
				1: 4 -- none
				0: 1 --standard
				default: 4
			)
		)

		--try to find a name for the new material
		if (oldMat.fileName == "" ) then
		(
			--name after diffuse
			if ((oldMat.mapEnables[1])  and (oldMat.maps[1].filename != undefined)) then
				newMat.name = getFilenameFile oldMat.maps[1].filename
			else
				newMat.name = oldMat.name --name as old material as last resort
		) else (
			--name after material file
			newMat.BGSMatInit=true
			newMat.BGSMatPathParam=oldMat.fileName
			newMat.BGSMatPathRelativeParam=getRelativeMatPath(oldMat.fileName)
			newMat.name = getFilenameFile newMat.BGSMatPathRelativeParam
		)

		--check for existing materials before assigning
		found=false
		foundMat=""

		for mat in sceneMaterials do (
			if classof newMat == classof mat then (
				if ((newMat.delegate.diffuseTexture as string == mat.delegate.diffuseTexture as string) and (newMat.delegate.normalTexture as string  == mat.delegate.normalTexture as string ) and (newMat.BGSMatPathRelativeParam==mat.BGSMatPathRelativeParam) ) then (
					for prop in (getPropNames newMat) do (
						if getProperty newMat prop != getProperty mat prop then exit
						found=true
						foundMat=mat
					)
				)
			)
		)

		if found then (
			oldMat=foundMat
			print ("Found matching material: " + oldMat.name)
		) else (
			--assign material and show texture in viewport
			print ("Made new mat: " +newMat.name)
			oldMat = newMat
			newMat.ShowTextureParam = on
		)

		return oldMat
	)

	-- standard to BSEffectFX
	fn standardToBSEFx oldMat =
	(
		--get old material and make a new BSEFX
		newMat = BSEffectFX()

		-------Add bitmaps----------
		--diffuse/base
		if oldMat.mapEnables[1] and (doesFileExist oldMat.maps[1].filename) then (
			--newMat.delegate.baseTexture = (openBitmap (oldMat.maps[1].filename))
			setproperty newMat.delegate "baseTexture" oldMat.maps[1].bitmap
			newMat.BaseTexEnableParam = on
		) else (
			if queryBox "No diffuse map texture found, this will make a material with no maps. Do you want to continue?" title:"Missing dds" then (
				newMat.BaseTexEnableParam = off
			)
			else (
				return oldMat
			)
		)
		--palette
		if ((oldMat.mapEnables[4]) and (doesFileExist oldMat.maps[4].filename)) then (
			--newMat.delegate.grayscaleTexture = (openBitmap (oldMat.maps[4].filename))
			setproperty newMat.delegate "grayscaleTexture" oldMat.maps[4].bitmap
			newMat.GrayscaleTexEnableParam = on
			--only set these if there is a texture for them
			newMat.GrayscaleColorParam=oldMat.grayscaleToPaletteColor
			newMat.GrayscaleAlphaParam=oldMat.grayscaleToPaletteAlpha
		)
		--Envmap
		if oldMat.EnvironmentEnable do (
			if (oldMat.Environment != undefined) then (
				if ((oldMat.maps[5].mapEnabled) and (doesFileExist oldMat.maps[5].map.filename)) then (
					--newMat.delegate.envmapTexture = (openBitmap (oldMat.maps[5].map.filename))
					setproperty newMat.delegate "envmapTexture" oldMat.maps[5].map.bitmap
					newMat.EnvmapTexEnableParam = on
				)
				--Envmap Mask
				if ((oldMat.maps[5].maskEnabled) and (doesFileExist oldMat.maps[5].mask.filename)) then (
					--newMat.delegate.envmapMaskTexture = (openBitmap (oldMat.maps[5].mask.filename))
					setproperty newMat.delegate "envmapMaskTexture" oldMat.maps[5].mask.bitmap
					newMat.EnvmapMaskTexEnableParam = on
				)
				else if ((oldMat.maps[5].mapEnabled) and (doesFileExist oldMat.maps[5].filename)) then (
						--newMat.delegate.envmapTexture = (openBitmap (oldMat.maps[5].filename))
						setproperty newMat.delegate "envmapTexture" oldMat.maps[5].bitmap
						newMat.EnvmapTexEnableParam = on
				)
			)
		)
		--Normal
		if ((oldMat.mapEnables[2]) and (doesFileExist oldMat.maps[2].normal_map.filename)) do (
			--newMat.delegate.normalTexture = (openBitmap (oldMat.maps[2].normal_map.filename))
			setproperty newMat.delegate "normalTexture" oldMat.maps[2].normal_map.bitmap
			newMat.NormalTexEnableParam  = on
		)

		newMat.BaseColorParam=oldMat.baseColor
		newMat.BaseColorScaleParam=oldMat.baseColorScale
		newMat.TwoSidedParam=oldMat.twoSided
		newMat.DecalParam=oldMat.decal
		newMat.DecalNoFadeParam=oldMat.decalNoFade
		newMat.ScreenSpaceReflectionsParam=oldMat.screenSpaceReflections
		newMat.FalloffParam=oldMat.falloffEnabled
		newMat.FalloffColorParam=oldMat.falloffColorEnabled
		newMat.FalloffStartAngleParam=oldMat.falloffStartAngle
		newMat.FalloffStopAngleParam=oldMat.falloffStopAngle
		newMat.FalloffStartOpacityParam=oldMat.falloffStartOpacity
		newMat.FalloffStopOpacityParam=oldMat.falloffStopOpacity
		newMat.ZTestParam=oldMat.zBufferTest
		newMat.ZWriteParam=oldMat.zBufferWrite
		newMat.LightingParam=oldMat.effectLightingEnabled
		newMat.LightingInfluenceParam=oldMat.lightingInfluence
		newMat.SoftParam=oldMat.softEnabled
		newMat.SoftDepthParam=oldMat.softDepth
		newMat.AlphaParam=oldMat.alphaTest
		newMat.AlphaValueParam=oldMat.alpha
		newMat.AlphaRefParam=oldMat.alphaTestRef
		newMat.BloodParam=oldMat.bloodEnabled

		newMat.EnvmapScaleParam=oldMat.environmentMappingMaskScale
		newMat.EnvmapMinLODParam=oldMat.envmapMinLOD
		newMat.RefractionParam=oldMat.refractionFalloff
		newMat.RefractionPowerParam=oldMat.refractionPower
		newMat.RefractionFireParam=oldMat.falloffColorEnabled
		newMat.BaseTexEnableParam=oldMat.diffuseMapEnable
		newMat.UTilingParam=oldMat.tileU
		newMat.VTilingParam=oldMat.tileV
		newMat.UOffsetParam=oldMat.uOffset
		newMat.VOffsetParam=oldMat.vOffset
		newMat.UScaleParam=oldMat.uScale
		newMat.VScaleParam=oldMat.vScale

		-- old mat has blendstate checkbox, new doesn't. So set to none if box is unchecked
		if oldMat.blendState==off then
			newMat.AlphaBlendParam=4
		else (
			newMat.AlphaBlendParam = case oldMat.alphaBlendMode of
			(
				4: 3 -- multiplicative
				3: 2 -- additive
				1: 4 -- none
				2: 1 --standard too
				0: 1 --standard
				default: 4
			)
		)

		--add material file if it exists and name the new material else name it to the diffuse or as last resort the old name
		if (oldMat.fileName == "") then
		(
			if ((oldMat.mapEnables[1]) and (oldMat.maps[1].bitmap != undefined)) then
				newMat.name = getFilenameFile oldMat.maps[1].filename
			else
				newMat.name = oldMat.name
		) else (
			newMat.BGSMatInit=true
			newMat.BGSMatPathParam=oldMat.fileName
			newMat.BGSMatPathRelativeParam=getRelativeMatPath(oldMat.fileName)
			newMat.name = getFilenameFile newMat.BGSMatPathRelativeParam
		)

		--check for existing materials before assigning
		found=false
		foundMat=""

		for mat in sceneMaterials do (
			if classof newMat == classof mat then (
				if ((newMat.delegate.baseTexture as string== mat.delegate.baseTexture as string) and (newMat.delegate.normalTexture as string == mat.delegate.normalTexture as string) and (newMat.BGSMatPathRelativeParam==mat.BGSMatPathRelativeParam)) then (
					for prop in (getPropNames newMat) do (
						if (getProperty newMat prop) != (getProperty mat prop) then exit
						found=true
						foundMat=mat
					)
				)
			)
		)

		if found then (
			oldMat=foundMat
			print ("Found matching material: " + oldMat.name)
		) else (
			--assign material and show texture in viewport
			print ("Made new mat: " +newMat.name)
			oldMat = newMat
			newMat.ShowBaseParam = on
		)

		return oldMat --lazy name... it's the new one
	)

	-- standard with Blinn Shader to BSLightingFX
	fn standardBlinnToBSLFx oldMat =
	(
		--get old material and make a new BSLFX
		newMat = BSLightingFX()
		print "Converting to BSLFX"
		-------Add bitmaps----------
		--diffuse
		if (oldMat.diffuseMapEnable) and (openBitmap (oldMat.diffuseMap.filename) != undefined) then (
				newMat.delegate.diffuseTexture = (openBitmap (oldMat.diffuseMap.filename))
				newMat.DiffuseEnableParam = on
		)  else (
			newMat.ShowTextureParam = off
		)
		--normal
		if ((oldMat.mapEnables[4]) and (openBitmap (oldMat.bumpMap.filename) != undefined)) then (
			newMat.delegate.normalTexture = (openBitmap (oldMat.bumpMap.filename))
			newMat.NormalEnableParam = on
		)
		--smooth/spec
		if ((oldMat.mapEnables[4]) and (openBitmap (oldMat.maps[4].filename) != undefined)) then (
			newMat.delegate.smoothspecmaskTexture = (openBitmap (oldMat.maps[4].filename))
			newMat.SmoothSpecEnableParam = on
		)

		--self illum / glow map
		if ((oldMat.mapEnables[6]) and (openBitmap (oldMat.maps[6].filename) != undefined)) then (
			newMat.delegate.smoothspecmaskTexture = (openBitmap (oldMat.maps[6].filename))
			newMat.SmoothSpecEnableParam = on
		)

		if oldMat.opacity <100 do newMat.AlphaBlendParam=1
		newMat.AlphaValueParam=oldMat.opacity/100
		newMat.DiffuseColorParam=oldMat.Diffuse

		if oldMat.specularLevel > 0 do newMat.SpecularParam=on
		newMat.SpecularColorParam=oldMat.Specular
		--newMat.SmoothnessParam=oldMat.smoothness
		newMat.SpecularScaleParam=oldMat.specularLevel/100
		newMat.ShowEmitParam=oldMat.useSelfIllumColor
		newMat.EmitScaleParam=oldMat.selfIllumAmount/100
		newMat.EmitColorParam=oldMat.selfIllumColor
		newMat.ApplyGlowmapToEmitParam=oldMat.selfillumMapEnable
		newMat.TwoSidedParam=oldMat.twoSided
		newMat.CastShadowsParam=on

		newMat.name = oldMat.name

		--assign material and show texture in viewport
		objMat = newMat
		newMat.ShowTextureParam = on

		return newMat
	)

	-- BSLightingFX to Standard a Figment
	fn BSLFxToFigment oldMat =
	(
		--get old material and make a new BSLFX
		newMat = standardMaterial()
		newMat.shaderType = 2

		--add the material file if exists
		if (oldMat.BGSMatInit) then
			newMat.fileName=oldMat.BGSMatPathParam

		-------Add bitmaps----------
		--diffuse
 		if (oldMat.DiffuseEnableParam) then (
			newMat.diffuseMap =bitmapTexture filename:oldMat.delegate.diffuseTexture.filename
 			newMat.diffuseMapEnable=on
 		)
		--normal
 		if (oldMat.NormalEnableParam) then (
			newMat.maps[2]=Normal_Bump ()
			newMat.maps[2].normal_map= bitmapTexture filename:oldMat.delegate.normalTexture.filename
 			newMat.mapEnables[2] = on
 		)
		--smooth/spec
		if (oldMat.SmoothSpecEnableParam) then (
			newMat.maps[3] =bitmapTexture filename:oldMat.delegate.smoothspecmaskTexture.filename
 			newMat.mapEnables[3]=on
 		)
		--greyscale/palette
		if (oldMat.GrayscaleTexEnableParam) then (
			newMat.maps[4] =bitmapTexture filename:oldMat.delegate.heightTexture.filename
 			newMat.mapEnables[4]=on
 		)
 		--Envmap
		if (oldMat.EnvmapEnableParam) then (
			newMat.maps[5] =bitmapTexture filename:oldMat.delegate.envTexture.filename
 			newMat.mapEnables[5]=on
 		)
 		--Glow
		if (oldMat.GlowEnableParam) then (
			newMat.maps[6] =bitmapTexture filename:oldMat.delegate.glowTexture.filename
 			newMat.mapEnables[6]=on
 		)
 		--wrinkle
		if (oldMat.WrinkleEnableParam) then (
			newMat.maps[8] =bitmapTexture filename:oldMat.delegate.wrinklesTexture.filename
 			newMat.mapEnables[8]=on
 		)

		newMat.alphaTest=oldMat.AlphaParam
		newMat.alpha=oldMat.AlphaValueParam

		newMat.alphaTestRef=oldMat.AlphaRefParam
		newMat.enableEditorAlphaRef=oldMat.EditorAlphaTestRef
		newMat.zBufferTest=oldMat.ZTestParam
		newMat.zBufferWrite=oldMat.ZWriteParam
		newMat.subsurfaceLighting=oldMat.SubSurfaceLightingParam
		newMat.subsurfaceLightingRolloff=oldMat.SubSurfaceRolloffParam
		newMat.backLightPower=oldMat.BackLightingPowerParam

		newMat.specularEnabled=oldMat.SpecularParam
		newMat.specularColor=oldMat.SpecularColorParam
		newMat.smoothness=oldMat.SmoothnessParam
		newMat.specularMult=oldMat.SpecularScaleParam

		newMat.emitEnabled=oldMat.ShowEmitParam
		newMat.emittanceMult=oldMat.EmitScaleParam
		newMat.emittanceColor=oldMat.EmitColorParam

		newMat.anisoLighting=oldMat.AnisoLightingParam
		newMat.glowmap=oldMat.ApplyGlowmapToEmitParam
		newMat.refraction=oldMat.RefractionParam
		newMat.refractionPower=oldMat.RefractionPowerParam
		newMat.refractionFalloff=oldMat.RefractionFireParam
		newMat.hair=oldMat.HairParam
		newMat.hairTintColor=oldMat.HairColorParam
		newMat.EnvironmentEnable=oldMat.EnvmapParam
		newMat.environmentMappingMaskScale=oldMat.EnvmapScaleParam
		newMat.environmentMappingEye=oldMat.EnvmapEyeParam
		newMat.environmentMappingWindow=oldMat.EnvmapWindowParam
		newMat.applyReflectionDimming=oldMat.EnvmapLightFadeParam
		newMat.tree=oldMat.TreeParam
		newMat.grayscaleToPaletteColor=oldMat.GrayscaleColorParam
		newMat.grayscaleToPaletteScale=oldMat.GrayscaleColorScaleParam
		newMat.twoSided=oldMat.TwoSidedParam
		newMat.modelSpaceNormals=oldMat.ModelSpaceNormalParam
		newMat.decal=oldMat.DecalParam
		newMat.decalNoFade=oldMat.DecalNoFadeParam
		newMat.externalEmittance=oldMat.ExternalEmittanceParam
		newMat.hideSecret=oldMat.HideSecretParam
		newMat.castShadows=oldMat.CastShadowsParam
		newMat.dissolveFade=oldMat.DissolveFadeParam
		newMat.screenSpaceReflections=oldMat.ScreenSpaceReflectionsParam
		newMat.nonOccluder=oldMat.NonOccluderParam
		newMat.tileU=oldMat.UTilingParam
		newMat.tileV=oldMat.VTilingParam
		newMat.uOffset=oldMat.UOffsetParam
		newMat.vOffset=oldMat.VOffsetParam
		newMat.uScale=oldMat.UScaleParam
		newMat.vScale=oldMat.VScaleParam


		if oldMat.AlphaBlendParam==4 then
			newMat.blendState==off
		else (
			newMat.alphaBlendMode = case oldMat.AlphaBlendParam of
			(
				3: 4 -- multiplicative
				2: 3 -- additive
				4: 1 -- none
				1: 0 --standard
				default: 4
			)
		)

		--try to find a name for the new material
		if (oldMat.BGSMatPathParam == "" ) then
		(
			--name after diffuse
			if (oldMat.DiffuseEnableParam) then
				newMat.name = getFilenameFile oldMat.delegate.diffuseTexture.filename
			else
				newMat.name = oldMat.name --name as old material as last resort
		) else (
			--name after material file
			newMat.name = getFilenameFile oldMat.BGSMatPathRelativeParam
		)

		--check for existing materials before assigning
		found=false
		foundMat=""

 		for mat in sceneMaterials do (
 			if classof newMat == classof mat then (
 				if ((newMat.diffuseMap as string == mat.diffuseMap as string) and (newMat.maps[2].normal_map as string  == mat.maps[2].normal_map as string ) and (newMat.fileName==mat.fileName) ) then (
					arr=getPropNames newMat
					for i=12 to arr.count do (	--stupid bug thing so need to skip some for now
						if getProperty newMat arr[i] != getProperty mat arr[i] then exit
						found=true
						foundMat=mat
 					)
 				)
 			)
 		)

		if found then (
			oldMat=foundMat
			print ("Found matching material: " + oldMat.name)
		) else (
			--assign material and show texture in viewport
			print ("Made new mat: " +newMat.name)
			oldMat = newMat
			showTextureMap NewMat on
		)

		return oldMat
	)

	--check to see what material type to make
	fn selector oldMat=
	(
		--get old material
		if (classof oldMat==StandardMaterial) then (
			if (oldMat.shaderByName == "Fallout 4 Shader") then (
				--always make BSEffectFX if material file is bgem
				if ((getFilenameType oldMat.filename) == ".BGEM") or (oldMat.baseTexture != undefined) then (
					return standardToBSEFx(oldMat)
				)
				else if (oldMat.fileName=="") or (ShaderType==2) or (oldMat.alphaBlendMode!=0) then (
					return standardToBSLFx(oldMat)
				) else (
					return standardToBSBlinn(oldMat)
				)
			)
			else if (oldMat.shaderByName=="Blinn" or oldMat.shaderByName=="Phong")  then return standardBlinnToBSLFx(oldMat)
		)
		else if ((classof oldMat==BSBlinn) and (ShaderType==3)) then (
			return BSBlinnToStandard(oldMat)
		)
		else if ((classof oldMat==BSLightingFX) and (ShaderType==3)) then (
			return BSLFxToFigment(oldMat)
		)
	)

	-- see if material already exists in scene, if so return that. Otherwise make a new one
	fn findBS objMat obj =
	(
		local newmat
		local oldbgsm
		local found=false
		print ("------------------------------")
		print ("Processing mesh: " + obj.name)

		try (
			if (classof objMat==StandardMaterial and objMat.shaderByName == "Fallout 4 Shader") do oldbgsm=objMat.filename
			if (classof objMat==BSBlinn) do oldbgsm=objMat.TargetMaterialFile
			if (classof objMat==BSLightingFX) do oldbgsm=objMat.BGSMatPathParam
			if (classof objMat==BSEffectFX) do oldbgsm=objMat.BGSMatPathParam

			if (oldbgsm!="") do (
				print oldbgsm
				print ShaderType
				for mat in sceneMaterials do (
					if (((getFilenameType oldbgsm) == ".BGEM") and (classof mat == BSEffectFX)) then (
						if (mat.BGSMatPathParam==oldbgsm) then (
							print ("Found match in existing BSEFX: "+ mat.name)
							newmat=mat
							found=true
						)
					) else if ( (ShaderType==1) and (classof mat == BSBlinn) ) then (
						if (mat.TargetMaterialFile==oldbgsm) then (
							print ("Found match in existing BSBlinn: "+ mat.name)
							newmat=mat
							found=true
						)
					) else if ( (ShaderType==2) and (classof mat == BSLightingFX) ) then (
						if (mat.BGSMatPathParam==oldbgsm) then (
							print ("Found match in existing BSLFX: "+ mat.name)
							newmat=mat
							found=true
						)
					) else if ( (ShaderType==3) and (classof mat==StandardMaterial ) ) then (
						if (mat.shaderByName == "Fallout 4 Shader" and mat.filename==oldbgsm) then
						(
							print ("Found match in existing material: "+ mat.name)
							newmat=mat
							found=true
						)
					)
				)
			)

		)catch (print ("error occured in " + obj.name))

		--return found mat or see what new material to make
		if found then return newmat
			else return (selector objMat)
	)

		--convert just selected objects materials
	fn convertSel=(
		local obj
		for obj in (Selection as array) do (
			if ((classof obj.material == Standardmaterial) or (classof obj.material == BSLightingFX) or (classof obj.material == BSBlinn)) then (
				obj.material=findBS obj.material obj
			) else if (classof obj.material==Multimaterial) then (
				for i=1 to obj.material.numsubs  do (
					if (classof obj.material.materialList[i]  == Standardmaterial) then (
						obj.material.materialList[i]=(findBS obj.material.materialList[i] obj)
					)
				)
			)
		)
	)

			--convert all the materials (from the geometry) in the scene
	fn convertAll=(
		local obj
		for obj in Geometry do(
			if ((classof obj.material == Standardmaterial) or (classof obj.material == BSLightingFX) or (classof obj.material == BSBlinn)) then (
				obj.material=findBS obj.material obj
			) else if (classof obj.material==Multimaterial) do (
				for i=1 to obj.material.numsubs  do (
					if (classof obj.material.materialList[i]  == Standardmaterial) then (
						obj.material.materialList[i]=(findBS obj.material.materialList[i] obj)
					)
				)
			)
		)
	)

	on btn_cnvA pressed do
	(
		ShaderType = Shader_Type.state
		convertAll()
	)
	on btn_cnvS pressed do
	(
		ShaderType = Shader_Type.state
		convertSel()
	)
)

------------------------  Export  -----------------------------------------------------------------------
rollout ExportRollout "Exporter"
(
	--get the export folder history
	fn getExportHistory =(
		pathArr=#()
		pathCount=GetINISetting (getMAXIniFile()) "ExportFile" "Count" as integer
		for i=0 to pathCount-1 do (
			append pathArr (GetINISetting (getMAXIniFile()) "ExportFile" ("History_0"+i as string))
		)
		return pathArr
	)

	--export selected as nif and add CPA if it exists
	fn nifexporter ePath iSel =(
		includes=#()
		shiftP=false
		ctrlP=false

		if keyboard.shiftPressed do shiftP=true
		if keyboard.controlPressed do ctrlP=true

		objs=(Selection as array)

		for sel in iSel do (
			selArr = (getnodebyname ExportRollout.mlbx1.items[sel] all:true)
			for cNode in selArr do (
				readHide=cNode.isHidden
				if readHide != true do
					append includes cNode
			)
		)

		for i=1 to objs.count do (
			if objs[i].name != "WorkshopConnectPoints" do (

				print ("Exporting nif: "+objs[i].name)

				for inc in includes do (
					if inc.name != objs[i].name do (
						print ("Including node: " + inc.name)
						inc.parent = objs[i]
					)
				)

				--if $WorkshopConnectPoints != undefined then (
				--	snapNode = $WorkshopConnectPoints
				--	oldSnapParent=snapNode.parent
				--	snapNode.parent = objs[i]
					select objs[i]
					if (shiftP and i==1) then (
						if (ctrlP) then (
							exportFile (ePath+ "\\"+objs[i].name+".nif") selectedOnly:true using:Niftools_NIF_Exporter
						) else (
							exportFile (ePath+ "\\"+objs[i].name+".nif") selectedOnly:true using:nif_export_class
						)
					) else (
						if (ctrlP) then (
							exportFile (ePath+ "\\"+objs[i].name+".nif") #noPrompt selectedOnly:true using:Niftools_NIF_Exporter
						) else (
							exportFile (ePath+ "\\"+objs[i].name+".nif") #noPrompt selectedOnly:true using:nif_export_class
						)
					)

				--unparent included nodes again
				for cNode in includes do (
					cNode.parent = undefined
				)
			)
		)
		select objs
	)

	--get root nodes that are not hidden
	fn getRootNodes=(
		rootNodeList=#()
		for nn in rootNode.children do (
			readHide=nn.isHidden
			if readHide != true do
				appendIfUnique rootNodeList nn.name
		)

		sort rootNodeList

		--put cpa first
		if ((findItem rootNodeList "WorkshopConnectPoints") > 0) do (
			CPA=rootNodeList[findItem rootNodeList "WorkshopConnectPoints"]
			deleteItem rootNodeList (findItem rootNodeList "WorkshopConnectPoints")
			insertItem CPA rootNodeList 1
		)

		return rootNodeList
	)


	--update the inlcude box manually and keep the layer manager open
	fn updateList=(
		ExportRollout.mlbx1.items=(getRootNodes())
		macros.run "Layers" "LayerManager"
	)

	multiListBox mlbx1 "Include on export" height:4 toolTip:"Ctrl click to deselect" items:(getRootNodes())
	dropdownList exportPath "" width:150 across:2 enabled:true readOnly:true items:(getExportHistory())
	button btn8 "..." width:20 align:#right toolTip:"Select Export Path"
	button btn_update "Update List" across:2
	button btn_export "Export Selected" toolTip:"Exports sel as nif with WorkshopConnectPoints included./nPress Shift to show Export Options."

	--To clear the list selection you might want to add a "Clear Selection" button that sets selection=#{}.
	on btn_update pressed do
	(
		updateList()
	)
	on btn_export pressed do
	(
		nifexporter (exportPath.text) (mlbx1.selection)
	)
	on btn8 pressed do
	(
		newPath=getSavePath caption:"Export Path" initialDir:exportPath.Selected
		if newPath != undefined do (
			exportPath.Selected=newPath
		)
		--getDir #maxroot
	)
)

------------------------  Snap utils ---------------------------------------------------------------------
rollout SnapRollout "Snap utils"
(
	local ActiveSnapNodeRoot = undefined

	--button btnRefreshValues "Refresh Snap Set" width:128 align:#center
	--button btnCloneSet "Clone Snap Sets" width:128 align:#center
	--dropdownlist comboSetName "Set Name:" enabled:false
	dropdownList ddl1 "Snap Name" items:theSnaps
	edittext edt1 "" enabled:false
	dropdownList ddl3 "" items:#("", "-Dif", "-Dif2")  across:3
	checkbox snapPosOn "" toolTip:"Zero Transform" align:#center
	button btn_snap "Make" width:64

	fn getCPANode=(
		local CPA=undefined
		if ($ != undefined) then (
			if ($.name == "WorkshopConnectPoints") then (
				CPA=$
			) else if ($.parent!=undefined) then (
				if ($.parent.name == "WorkshopConnectPoints") then (
					CPA=$.parent
				) else  (
					local root=GetRootsFromSelection()
					rchildren=root[1].children
					index=0

					for obj in test do
					(
						if obj.name == "WorkshopConnectPoints"  then
							exit
						else
							index = index + 1
					)
					if index > 0 do
						CPA=rchildren[index+1]
				)
			)
		)
		return CPA
	)

	fn makeSnap snapName=(
		--press shift while making snap to insert into a parent
		local shiftP=false
		if keyboard.shiftPressed do shiftP=true
		local root=GetRootsFromSelection()

		--try to set current layer by name of root node
		if root[1]!=undefined then (
			curLayer=LayerManager.getLayerFromName root[1].name
			if curLayer!=undefined do
				(LayerManager.getLayerFromName root[1].name).current = true
		)
		--add the point
		pt = point name:(snapName) size:40 Box:off cross:off axistripod:on centermarker:on constantscreensize:off drawontop:off
		pt.wirecolor = yellow
		setUserProp pt "sgokeep" 1

		--set default posistion of the snap, toogled by the checkbox
		if snapPosCheck == off do (
			snapPos = case snapName of --or snapName?
			(
				"P-Wall01": pt.pos = [0,-8,98.5]
				"P-Wall01-Dif": pt.transform  = (matrix3 [0,1,0] [-1,0,0] [0,0,1] [-128,-8,98.5])
				"P-Wall01-Dif2": pt.transform = (matrix3 [0,-1,0] [1,0,0] [0,0,1] [128,-8,98.5])
				"P-Balcony01-Dif": pt.pos = [64,0,0]
				"P-Door": pt.pos = [0,0,84]
				"P-Door-Dif": pt.pos = [0,0,84]
				"P-Door-Dif2": pt.pos = [0,0,84]
				"P-Ceiling": pt.pos = [0,0,260]
				"P-Ceiling-Dif": pt.pos = [0,0,260]
				"P-Stack-Dif": pt.pos = [0,0,16]
				"P-Stack-Dif2": pt.transform = (matrix3 [-1,-1.50996e-007,0] [1.50996e-007,-1,0] [0,0,1] [0,0,272])
				"P-HouseKCapWallpaper-Dif2": pt.transform = (matrix3 [0,-1,0] [1,0,0] [0,0,1][0,112,98.5])
				"P-HouseKCapWallpaper-Dif": pt.transform = (matrix3 [0,1,0] [-1,0,0] [0,0,1][0,0,98.5])
				"P-WrhsWallCorner01-Dif2": pt.transform = (matrix3 [0,-1,0] [1,0,0] [0,0,1] [128,0,16])
				"P-WrhsWallCorner01-Dif": pt.pos  = [-128,0,16]
				"P-Sandwich": pt.pos = [0,0,96]
				default: pt.pos = [0,0,0]
			)
		)
		if selection!=undefined do
			pt.parent = selection[1]

		if shiftP then (
			local CPA=getCPANode()

			--if no WorkshopConnectPoints dummy exists create one
			if ( CPA ==undefined ) do (
				CPA = point name:"WorkshopConnectPoints" size:30 Box:on cross:off axistripod:off centermarker:on constantscreensize:off drawontop:off
				setUserProp CPA "sgokeep" 1
				CPA.wirecolor = blue
				setUserProp CPA SnapNode_BASE_NAME true
				ActiveSnapNodeRoot = CPA
			)

			pt.parent = CPA
		)

		select pt
	)

	on ddl1 selected i do
	(
		if ddl1.items[i] == "Custom" then
		(
			edt1.enabled = true
			setFocus edt1
		) else (
			edt1.enabled = false
		)
	)

	on comboSetName selected item do
	(
		local SnapNodeName = comboSetName.items[item]
		ActiveSnapNodeRoot = getNodeByName SnapNodeName exact:true
		if comboSetName.selection > 1 do
			select (getNodeByName SnapNodeName exact:true)
	)

	on snapPosOn changed theState do snapPosCheck=snapPosOn.checked

	on btn_snap pressed do
	(

			if ddl1.selected == "Custom" then (
				if edt1.text != "" do makeSnap(edt1.text+ddl3.selected)
				--Because insertItem returns OK instead of the resulting array, --you cannot assign the result of the expression directly to the property. --Instead, you have to get a copy of the items array in a local variable...
				temp_array = ddl1.items
				--...perform the insertion with the temp. array in the local variable...
				insertItem edt1.text temp_array ddl1.selection
				--...and assign back the temp. array to the .items property
				ddl1.items = temp_array
				--ddl1.items = append ddl1.items edt1.text
				edt1.enabled = false
				--save new snap in ini file
				Count = (getinisetting iniFolder "Snaps").count
				try(setinisetting iniFolder "Snaps" ("Snap"+((Count+1) as string)) (edt1.text))Catch("Can't save settings, run in Admin to save!")
			) else (
				makeSnap(ddl1.selected+ddl3.selected)
			)

	)

	on btnRefreshValues pressed do
	(
			RefreshSnapNodeGroups()
	)

	on btnCloneSet pressed do
	(
			cloneSnapSet()
	)

)

-------------------------  Misc  -------------------------------------------------------------------------
rollout MiscRollout "Misc utils"
(
	button btn_mirc "Poly mod" width:80 tooltip:"Add Edit poly modifiers to sel"
	--button btn5 "Mat to Sel" pos:[8,31] width:70 height:21 tooltip:"Assign material to selection"
	button btn5 "Vert Col Sel" width:80 across:2 tooltip:"Assign new vertex color to selection"
	button btn_mrg "Merge by Mat" width:80 tooltip:"Merges selection by material"
	button btn_unwrap "Unwrap UVW" across:2 width:80 tooltip:"Add UVWUnwrap modifier"
	button btn_UVBox "UVW Box" width:80 tooltip:"Adds UVW box mod (256x256x256) to sel"
	button btn_cloner "Clone" width:80 across:2 tooltip:"Clone to same name"
	button btn_xform "Reset XForm" width:80 tooltip:"BS reset Xform util. No undo!\nHold Shift to move pivot to zero."

	fn xFormFix=(
		shiftP=false
		if keyboard.shiftPressed do shiftP=true

		objs=(Selection as array)
		for obj in objs do (
			if shiftP do obj.pivot = [0,0,0]
			select obj
			try(macros.run "Bethesda" "BSFixXForms")catch()
		)
		select objs
	)

	fn cloner=(
		objs=(Selection as array)
		for obj in objs do (
			obj.name = obj.name + ":"
			if obj.children.count > 0 do (
				for c in obj.children do (
					c.name = c.name + ":"
				)
			)
			maxOps.cloneNodes (obj) cloneType:#copy expandHierarchy:true newNodes:&nmo #nodialog
			for i = 1 to nmo.count do
			(
				nmo[i].name = substring nmo[i].name 1 (nmo[i].name.count-4)
			)
			obj.name = substring obj.name 1 (obj.name.count-1)
			if obj.children.count > 0 do (
				for c in obj.children do (
					c.name = substring c.name 1 (c.name.count-1)
				)
			)
		)
	)

	-- clone, mirror and add edit poly mod
	fn mirrorClone=(
		shiftP=false
		if keyboard.shiftPressed do shiftP=true

		objs=(Selection as array)
		for obj in objs do (
			--modPanel.addModToSelection (Edit_Poly ())
			addmodifier obj  (Edit_Poly ())
			if shiftP do (
				maxOps.cloneNodes obj cloneType:#copy newNodes:&nnl
				select obj
				for newnode in nnl do (
					select newnode
				--modPanel.addModToSelection (mirror ())
					addmodifier newnode  (mirror ())
					newnode.modifiers[#Mirror].mirror_axis = 1
				)
			)
		)
		select objs
	)

	fn UVBox=(
		objs=(Selection as array)

		newUV = Uvwmap() -- create a new UVWmap Modifier
		newUV.maptype = 4
		newUV.length = 256
		newUV.height = 256
		newUV.width = 256
		--giz=newUV.gizmo SubAnim
		--giz.position=[0,0,128]
		for obj in objs do (
			if superclassof(obj) == GeometryClass do (
				select obj
				addmodifier obj newUV  -- apply the modifier to the object
				redrawviews()
				obj.modifiers[1].gizmo.position=[obj.center.x,obj.center.y,(newUV.height/2)]
			)
		)
		select objs
	)

	fn unwrap=(
		objs=(Selection as array)
		newmod=Unwrap_UVW()
		for obj in objs do (
			if superclassof(obj) == GeometryClass do (
				select obj
				addmodifier obj  newmod-- apply the modifier to the object
			)
		)
		select objs
	)

	fn vertCol=(
		local clr=colorPickerDlg (color 255 255 255) "Pick A Better Color:" alpha:true pos:[100,100]
		for obj in (Selection as array)  do (
			converttopoly obj
			polyop.setvertcolor obj 0 #{1..obj.mesh.numverts} clr
		)
	)

	--add material to selection
	fn wallmat=(
		objs=(Selection as array)
		mat=materialBrowseDlg #mats #instanceOnly
		--obj.material = sceneMaterials["BldWallsRedFull03.bgsm"]
		for obj in objs do (
			obj.material=mat
			--modi=$'ResNCA2FLWallB02:003'.modifiers[#UVW_Map]
			--addModifier sel modi
		)
	)

	fn merger = (
		mtl = #() ; tmp = #() ; fin = #()
		sel = selection as array
		if sel.count == 0 then -- check selection
			messageBox "Nothing selected!" title:"Attach Mesh by Material"
		else
		(	-- filter selection
			sel = for i in sel where canConvertTo i Editable_Poly \
				and i.material != undefined collect i
			if sel.count <= 1 then -- 2nd check
				messageBox "Procedure requered\nmore then 1 valid objects\nwith assigned materials!" title:"Attach Mesh by Material"
			else
			(
				for i in sel do
				(
					if findItem mtl i.material == 0 do
						append mtl i.material
				)
				for m in mtl do
				(
					tmp = for i in sel where i.material == m collect i
					append fin tmp
				)
				undo on
				(
					clearSelection()
					for i in fin do
					(
						if i.count > 1 do
						(
							trg = snapshot i[1]
							selectMore trg
							if classof trg != Editable_Poly then converttopoly trg
							--delete i[1] -- del source obj
							deleteItem i 1 -- del item array
							for j in i do
								--meshop.attach trg j attachMat:#IDToMat condenseMat:true
								polyop.attach trg j
						)
					)
				)
			)
		)
	)

	on btn_UVBox pressed do
	(
		UVBox()
	)
	on btn_unwrap pressed do
	(
		unwrap()
	)
	on btn_mirc pressed do
	(
		mirrorClone()
	)
	on btn_xform pressed do
	(
		xFormFix()
	)
	on btn5 pressed do
	(
		--wallmat()
		vertCol()
	)
	on btn_mrg pressed do
	(
		merger()
	)
	on btn_cloner pressed do
	(
		cloner()
	)
)

-------------------------  Copy and Collision  -----------------------------------------------------------
rollout HavokRollout "Copy" width:160 height:128
(
	local ColLay
	local ColMat

	fn havokMod obj shiftP =(
		clayer=ColLay
		obj.name = uniqueName ("c_" + obj.name) numDigits:2
		collapseStack obj
		addmodifier obj (Havok_Shape())
		if shiftP then obj.modifiers[#Shape].shapeType = 4 else obj.modifiers[#Shape].shapeType = 5
		setUserPropBuffer obj ("ColGroupVersion = 1\r\nColGroupInfo = "+((ColLay-1) as String)+"\r\nColGroupLastMat = "+ ColMat +"\r\nColGroupMatCRC =" + (bscrc32_lower(ColMat) as string) )
	)

	fn wreakhavok = (
		shiftP=false
		if keyboard.shiftPressed do shiftP=true

		--if faces or elements are selected make a new node from them and use that
		if (subObjectLevel==4 or subObjectLevel==5) then (
			sel = selection[1]

			if sel.selectedFaces.count >= 1 and classof sel.baseobject == Editable_Poly do (
				local polyList = #{}
				local nName = uniqueName sel.name
				if (subObjectLevel==4 ) do polyList = polyOp.getFaceSelection sel
				if (subObjectLevel==5 ) do polyList=polyop.getElementsUsingFace sel sel.selectedFaces
				polyOp.detachFaces sel polyList delete:false asNode:true name:nName

				newNode=getnodebyname nName
				newNode.parent=sel.parent

				if ((polyOp.getNumFaces sel) == 0) then
				(
					delete sel
				)

				select newNode
				havokMod newNode ShiftP

				select sel
			)
		) else (
			--if no subobject selected clone the lot of the selected objects into a new array
			arr = (selection as array)
			maxOps.cloneNodes (arr) cloneType:#copy newNodes:&nco #nodialog

			for i=1 to nco.count do
			(
				havokMod nco[i] ShiftP
			)
		)
	)

	fn makebaby bnam = (
		arr = (selection as array)
		--make a check to see if exists first..
		if LayerManager.getLayerFromName bnam == undefined then (
			layer= layermanager.newLayerFromName bnam
			layer.current = true
		) else (
			layer = LayerManager.getLayerFromName bnam
			layer.current = true
		)

		rootN=Dummy pos:[0,0,0] isSelected:on
		rootN.name=bnam
		layer.addnode rootN
		addmodifier rootN(Havok_Rigid_Body ())

		maxOps.cloneNodes (arr) cloneType:#copy newNodes:&nmo #nodialog

		for i = 1 to nmo.count do
		(
			nmo[i].name = uniqueName (bnam+":") numDigits:2
			layer.addnode nmo[i]
			nmo[i].parent=rootN
		)
	)

	fn LoadBSHavokMaterialTypes cfgFile=
	(
		BSHavokMaterialTypes =#()
		HavokMaterialConfigFileName = cfgFile+".cfg"
		-- Error dialog
		rollout FileNotFound "File Not Found" width:300 height:50
		(
			label NotFoundLabel "Could not find/open Materials.cfg file"
		)

		local configPath = INI_GetConfigsDir()
		if configPath != undefined and HavokMaterialConfigFileName != undefined then
		(
			configPath = configPath + HavokMaterialConfigFileName
		)

		matConfigFile = openFile configPath mode:"rt"
		if matConfigFile != undefined then
		(
			while not eof matConfigFile do
			(
				matLine = readLine matConfigFile
				if(matLine.count != 0 and matLine[1] != ";") then
					append BSHavokMaterialTypes matLine
			)
		)
		return BSHavokMaterialTypes
	)

	edittext edt_A "Name"
	button btn_cpy "Copy as New" toolTip:"Copy sel into a new dummy and layer"
	group "Collision" (
		dropdownList ddl2 "Layer" items:(LoadBSHavokMaterialTypes("CollisionLayers")) selection:2
		dropdownList ddl_A "Material" items:(LoadBSHavokMaterialTypes("CollisionMaterials")) --#("Brick", "Carpet", "Cloth", "Concrete", "Dirt", "Glass", "Grass", "Metal", "Paper", "Plastic", "Stone", "Wood", "Generic")
		button btn_whk "Copy as Collsion" toolTip:"Copy sel as havok shape - Mesh.\nHold Shift for Convex Hull"
	)

	on btn_cpy pressed do
	(
		if ((edt_A.text != "") and ($ != undefined)) then makebaby edt_A.text else setFocus edt_A
	)
	on btn_whk pressed do
	(
		ColLay=ddl2.selection
		ColMat=ddl_A.selected
		Print("lay: "+ColLay as string)
		Print("mat: "+ColMat as string)
		wreakhavok()
	)
)

rollout aboutRollout "About"
(
	label lbl6 "by robboten 2018"
	label lblv vers
)

fn launcher=(
	try(destroyDialog fo4utilsDialog)catch()

	fo4utilsDialog = newRolloutFloater "FO4 Utils" 220 720
	addrollout ConvertRollout fo4utilsDialog rolledUp: true
	addrollout SnapRollout fo4utilsDialog rolledUp: true
	addrollout HavokRollout fo4utilsDialog rolledUp: true
	addrollout MiscRollout fo4utilsDialog rolledUp: true
	addrollout ExportRollout fo4utilsDialog
	addrollout AboutRollout fo4utilsDialog  border:false

	--add "Custom" to Snap drop down
	SnapRollout.ddl1.items= append SnapRollout.ddl1.items "Custom"

	macros.run "Layers" "LayerManager"
 )

--on fo4utils open do
--(
	--macros.run "Layers" "LayerManager"
	--callbacks.addScript #filePostOpen "fo4utils.updateList()" id:#fpopen

	--fo4utils.launcher()
--)

--on fo4utils close do
--(
	--try (closeRolloutFloater fo4utilsDialog) catch(format"error closing stuff\n")
	--try (DestroyDialog fo4utilsDialog) catch()

	--callbacks.removeScripts id:#relink
	--callbacks.removeScripts id:#fpopen
--)

launcher()

) --end util
