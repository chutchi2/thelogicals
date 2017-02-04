<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:user="http://www.ni.com/TestStand" xmlns:vb_user="http://www.ni.com/TestStand/" id="TS5.1.0">

	<!--This alias is added so that the html output does not contain these namespaces. The omit-xml-declaration attribute of xsl:output element did not prevent the addition of these namespaces to the html output-->
	<xsl:namespace-alias stylesheet-prefix="xsl" result-prefix="#default"/>
	<xsl:namespace-alias stylesheet-prefix="msxsl" result-prefix="#default"/>
	<xsl:namespace-alias stylesheet-prefix="user" result-prefix="#default"/>
	<xsl:namespace-alias stylesheet-prefix="vb_user" result-prefix="#default"/>

	<!--VBScript Section: Contains only one function GetLocalizedDecimalPoint().This function will return the localized decimal point for a decimal number.-->
	<msxsl:script language="vbscript" implements-prefix="vb_user"><![CDATA[
		Function GetLocalizedDecimalPoint ()
			dim lDecPoint
			lDecPoint = Mid(CStr(1.1),2,1)
			GetLocalizedDecimalPoint = lDecPoint
		End Function
	]]></msxsl:script>
	<msxsl:script language="javascript" implements-prefix="user"><![CDATA[
	//Javascript Section 1: Adding report options to global information
	var gUseLocalizedDecimalPoint = 0;
	var gLocalizedDecimalPoint = "";
	var gNumericFormatRadix = 10;
	var gNumericFormatSuffix = "";
	
	// This function initializes the base or prefix path global variables
	var gStyleSheetPathPrefix = "";
	var gStoreStylesheetAbsolutePath = 1;
	
	function InitStylesheetPath(nodelist)
	{
		var reportOptionsNode = nodelist.item(nodelist.length-1);
		var stylesheetPath = reportOptionsNode.selectSingleNode("Prop[@Name='StylesheetPath']/Value").text;
		var storeStylesheetAbsolutePath = reportOptionsNode.selectSingleNode("Prop[@Name='StoreStylesheetAbsolutePath']/Value").text;

		gStyleSheetPathPrefix = GetFolderPath(stylesheetPath);
		gStoreStylesheetAbsolutePath = (storeStylesheetAbsolutePath == "True") ? 1 : 0;

		return "";
	}
	
	// This function sets the radix for the current numeric format
	function InitNumericFormatRadix(nodelist)
	{
		var reportOptionsNode = nodelist.item(0);
		var numericFormatString = reportOptionsNode.selectSingleNode("Prop[@Name='NumericFormat']/Value").nodeTypedValue;
		var formatSpecifierIndex = numericFormatString.search(/[diuxobefg]/i);
		gNumericFormatSuffix = numericFormatString.substring(formatSpecifierIndex+1);
		numericFormatString = numericFormatString.charAt(formatSpecifierIndex);
		switch (numericFormatString)
		{
			case 'o':
			case 'O':
				gNumericFormatRadix = 8;
				break;
			case 'x':
			case 'X':
				gNumericFormatRadix = 16;
				break;
			case 'b':
			case 'B':
				gNumericFormatRadix = 2;
				break;
			default:
				gNumericFormatRadix = 10;
		}
		return "";
	}
		
	// This function initializes all flag global variables
	var gIncludeArrayMeasurement = 0;
	var gArrayMeasurementFilter = 0;
	var gArrayMeasurementMax = 0;
	var gIncludeTimes = 0;
					
	function InitFlagGlobalVariables(nodelist)
	{
		var reportOptionsNode = nodelist.item(0);

		gIncludeArrayMeasurement = ConvertToDecimalValue(reportOptionsNode.selectSingleNode("Prop[@Name='IncludeArrayMeasurement']/Value").nodeTypedValue);
		gArrayMeasurementFilter = ConvertToDecimalValue(reportOptionsNode.selectSingleNode("Prop[@Name='ArrayMeasurementFilter']/Value").nodeTypedValue);
		gArrayMeasurementMax = ConvertToDecimalValue(reportOptionsNode.selectSingleNode("Prop[@Name='ArrayMeasurementMax']/Value").nodeTypedValue);
		gIncludeTimes = (reportOptionsNode.selectSingleNode("Prop[@Name='IncludeTimes']/Value").nodeTypedValue == 'True');
		var useLocalizedDecimalPointNode = reportOptionsNode.selectSingleNode("Prop[@Name='UseLocalizedDecimalPoint']");
		// Do this so that old reports can also use the new style sheet
		if (useLocalizedDecimalPointNode)
			gUseLocalizedDecimalPoint = (reportOptionsNode.selectSingleNode("Prop[@Name='UseLocalizedDecimalPoint']/Value").nodeTypedValue == 'True');

		return "";
	}
	
	// This function initializes all color global variables
	var gLabelBgColor = "";
	var gValueBgColor = "";
	var gMainBgColor = "";
	var gSetupBgColor = "";
	var gCleanupBgColor = "";
	var gTableBorderColor = "";
	
	function InitColorGlobalVariables(nodelist)
	{
		var colorsNode = nodelist.item(0);

		gLabelBgColor = colorsNode.selectSingleNode("Prop[@Name='LabelBg']/Value").text;
		gValueBgColor = colorsNode.selectSingleNode("Prop[@Name='ValueBg']/Value").text;
		gMainBgColor = colorsNode.selectSingleNode("Prop[@Name='MainBg']/Value").text;
		gSetupBgColor = colorsNode.selectSingleNode("Prop[@Name='SetupBg']/Value").text;
		gCleanupBgColor = colorsNode.selectSingleNode("Prop[@Name='CleanupBg']/Value").text;
		gTableBorderColor = colorsNode.selectSingleNode("Prop[@Name='TableBorder']/Value").text;
		
		return "";
	}

	//Javascript Section 2: Functions to handle localized decimal values.
	function SetLocalizedDecimalPoint(lDPoint)
	{
		gLocalizedDecimalPoint = lDPoint;
		return "";
	}
		
	// Function returns the localized decimal val from a node
	function ReturnLocalizedDecimalVal_Node(node)
	{
		var localizedNode = node.text;
		if (gUseLocalizedDecimalPoint)
		{
			var tempNode = node.text;
			localizedNode = tempNode.replace(".", gLocalizedDecimalPoint)
		}
		return localizedNode;
	}

	//Javascript Section 3: Functions to handle indentation and block levels for the tables in the report.     	
	// This variable stores the width for the second column
	var gSecondColumnWidth = 37;
	var gMaxBlockLevel = 100; // This is the max blockLevel supported in the report
	var gResultLevel = -1;
	var gBlockLevelArray;
	var gIndentationWidth = 40;
	var gIndentationLevel = 0;
	
	// This method returns the indentation level
	function GetIndentationLevel()
	{
		return gIndentationLevel;
	}
	
	// This method sets the indentation level
	function SetIndentationLevel(curSeqCallLevel)
	{
		gIndentationLevel = curSeqCallLevel;
		return "";
	}
	// This method returns the indentation width for div elements
	function GetIndentationWidth()
	{
		return gIndentationWidth;
	}

	// This sets the depth of the results being processed
	function SetResultLevel(curResultLevel)
	{
		if (curResultLevel < gMaxBlockLevel)
			gResultLevel = curResultLevel;
		else
			gResultLevel = gMaxBlockLevel
		return "";
	}
	
	// This sets the current Block Level of the result being processed
	function SetBlockLevel(curBlockLevel)
	{
		gBlockLevelArray[gResultLevel] = curBlockLevel;
		return "";
	}
	
	function GetResultLevel()
	{
		return gResultLevel;
	}
	
	function GetBlockLevel()
	{
		return gBlockLevelArray[gResultLevel];
	}
	
	// This function creates the BlockLevelArray and init the array to 0;
	function InitBlockLevelArray()
	{
		gBlockLevelArray= new Array(gMaxBlockLevel);
	
		for (var i = 0; i < gMaxBlockLevel; i++)
		{
			gBlockLevelArray[i] = 0;
		}
		// Set the ResultLevel to 0
		gResultLevel = 0;
		return "";
	}
	
	function ProcessCurrentBlockLevel(nodelist)
	{
		var node = nodelist.item(0);
		var node1 = node.selectSingleNode("Prop[@Name='TS']/Prop[@Name='BlockLevel']");
		var curStepBlockLevel  = -1;
		if (node1)
			curStepBlockLevel = ConvertToDecimalValue(node.selectSingleNode("Prop[@Name='TS']/Prop[@Name='BlockLevel']/Value").nodeTypedValue);
		
		if( curStepBlockLevel == -1)
				return "";
		if (curStepBlockLevel != GetBlockLevel())
		{
			SetIndentationLevel(GetIndentationLevel() + parseInt(curStepBlockLevel - GetBlockLevel(), 10));
			SetBlockLevel(curStepBlockLevel);
		}
		return "\n";
	}
	
	// This function generates an indentation string based on the block level
	function GetIndentationString(nLevel)
	{
		var sIndent = "";
		for (var i = 0; i < nLevel; i++)
		{
			sIndent += "___";
		}
		return sIndent;
	}

	//Javascript Section 4: Functions to insert 'looping' step results into the report.   
	// This function initializes the global array used to store loop index counts
	var gLoopNodeArray;
	var gLoopCounterArray;
	var gFirstLoopIndexArray;
	var gLoopStackDepth = -1;
	function InitLoopArray(nodelist)
	{
		var node = nodelist.item(0);
		var loopStartNodes = node.selectNodes(".//Prop[@Name='NumLoops']");
		var maxStackDepth = loopStartNodes.length;

		gLoopNodeArray = new Array(maxStackDepth);
		gLoopCounterArray = new Array(maxStackDepth);
		gFirstLoopIndexArray = new Array(maxStackDepth);

		for (var i = 0; i < maxStackDepth; i++)
		{
			gLoopNodeArray[i] = null;
			gLoopCounterArray[i] = 0;
			gFirstLoopIndexArray[i] = false;
		}

		return "";
	}

	// This function stores necessary information used to process loop index step results.  
	// The Loop Stack Depth counter is not incremented here since loop step results may be disabled.
	function BeginLoopIndices(nodelist)
	{
		var node = nodelist.item(0);
		var loopStackDepthPlus1 = gLoopStackDepth + 1;
		
		gLoopNodeArray[loopStackDepthPlus1] = node;
		gLoopCounterArray[loopStackDepthPlus1] = ConvertToDecimalValue(node.selectSingleNode("Prop[@Name='TS']/Prop[@Name='NumLoops']/Value").nodeTypedValue);
		gFirstLoopIndexArray[loopStackDepthPlus1] = true;

		return "";
	}

	// This function checks to see if this is the first loop step result.  If yes, it opens the div and increments the loop stack depth counter.
	function TestForStartLoopIndex()
	{
		if (gFirstLoopIndexArray[gLoopStackDepth + 1])
		{
			var loopNode;
			var stepName;
			var img;
			var id;
			var style;
			var sRet = "";

			gLoopStackDepth++;
			gFirstLoopIndexArray[gLoopStackDepth] = false;

			loopNode = gLoopNodeArray[gLoopStackDepth];
			stepName = loopNode.selectSingleNode("Prop[@Name='TS']/Prop[@Name='StepName']/Value").nodeTypedValue;

			// Get image text before id text
			img = GetStepResultImageFromNode(loopNode);
			id = GetIdFromNode(loopNode,"s");
			style = GetDIVStyleFromNode(loopNode);

			sRet += img + "<b style='white-space:nowrap'>" + stepName + "(Loop Indices)</b><br>";
			sRet += "<div class='LoopIndices' id='" + id + "' style='" + style + "'>";
			SetIndentationLevel(GetIndentationLevel() + 1);

			return sRet;
		}
		else
			return "";
	}
	
	// This function checks to see if all loop step results have been seen.  If yes, it closes the div and decreases the loop stack depth counter.
	function TestForEndLoopIndex()
	{
		if (--gLoopCounterArray[gLoopStackDepth] == 0)
		{
			gLoopNodeArray[gLoopStackDepth] = null;
			gLoopStackDepth--;
			SetIndentationLevel(GetIndentationLevel() - 1);
			return "</div>";
		}
		else
			return "";
	}
	
	// These functions are used to store the gLoopStackDepth to prevent issues while a sequence call step is looping and 
	// a step inside the sequence is also looping but has disabled result recording for each iteration
	var gMaxLoopingArraySize = 100;
	var gLoopingInfoArray;
	function InitLoopingInfoArray()
	{
		gLoopingInfoArray = new Array(gMaxLoopingArraySize);
		for (var i = 0; i < gMaxLoopingArraySize; i++)
		{
			gLoopingInfoArray[i] = 0;
		}
		// ResultLevel is set in InitBlockLevelArray()
		return "";
	}

	function StoreCurrentLoopingLevel()
	{
		gLoopingInfoArray[GetResultLevel()] = gLoopStackDepth;
		return "";
	}
	
	function RestoreLoopingLevel()
	{
		gLoopStackDepth = gLoopingInfoArray[GetResultLevel()] ;
		gFirstLoopIndexArray[gLoopStackDepth+1] = false;
		return "";
	}

	//Javascript Section 5: Functions to insert Arrays into the report as Graph objects
	// This style sheet might show tables instead of graphs for arrays of values if 
	// 1. TSGraph control is not installed on the machine
	// 2. Using the stylesheet in windows XP SP2. Security settings prevent stylesheets from creating the GraphControl using scripting. 
	// Refer to the TestStand Readme for more information.
	//GraphArray is an object to help graph 2D arrays
	function GraphArray(sLBound, sHBound)
	{
		this.LBoundElements = (sLBound.substring(1).replace(/]/g,"")).split("[");
		this.HBoundElements = sHBound.substring(1).replace(/]/g,"").split("[");
		this.Dimensions = sLBound.split("[").length - 1;
		
		this.SizeString = "";
		var i = 0;
		
		for(i = 0; i < this.LBoundElements.length; ++i)
		{
			this.SizeString += "[" + this.LBoundElements[i] + ".." + this.HBoundElements[i] + "]";
		}
		
		if(this.Dimensions == 2)
		{
			this.GraphSize = ( this.HBoundElements[1] - this.LBoundElements[1] + 1)* (this.HBoundElements[0] - this.LBoundElements[0] + 1);
			this.NumberOfGraphs = this.HBoundElements[0] - this.LBoundElements[0] + 1; 
			this.NumberOfColPlots = this.HBoundElements[1] - this.LBoundElements[1] + 1;
		}
		else
		{
			this.GraphSize = this.HBoundElements[this.Dimensions - 1] - this.LBoundElements[this.Dimensions - 1] + 1;
			this.NumberOfGraphs = 1;
		}
		
		this.Graphs = new Array();
		for(i = 0; i < this.NumberOfGraphs; ++i)
		{
			this.Graphs[i] = new Array();
		}
		
		//GraphArray methods:
		this.AddElementToGraph = AddElementToGraph;
		this.GetGraphData = GetGraphData;
		this.Get2DArrayData = Get2DArrayData;
	}

	function AddElementToGraph(element)
	{
		if(this.Dimensions == 1)
		{
			this.Graphs[0].push(element.text);
		}
		else
		{
			var elementIndexes = (element.getAttribute("ID").substring(1).replace(/]/g,"")).split("[");
			this.Graphs[elementIndexes[0] - this.LBoundElements[0]].push(element.text);
		}
	}

	function GetGraphData(index)
	{
		return this.Graphs[index].join(",");
	}

	//	Returns decimated 2D Array as Array( Array(1st Row), Array(2nd Row) )
	function Get2DArrayData(inc, colBasedDecimate, nMaxRows, nMaxCols)
	{
		var sRet = "";
		var i = 0;
		var j = 0;
		var rowInc = inc;
		var colInc = inc;
		var numRowsDisplayed = 0;
		var numColsDisplayed = 0;
    
		if (colBasedDecimate)
      		colInc = 1;
		else
      		rowInc = 1;
    
		sRet += "Array( Array(";

		for(i = 0; i < this.NumberOfGraphs; i += rowInc)
		{
			if(++numRowsDisplayed > nMaxRows)
				break;
			if (i > 0)
				sRet += ", Array(";
			numColsDisplayed = 0;
			for (j = 0; j < this.Graphs[i].length; j += colInc)
			{
				if(++numColsDisplayed > nMaxCols)
					break;
				if (j > 0)
					sRet += ", ";
				sRet += this.Graphs[i][j];
			}
			sRet += ")";
		}
		sRet += ")";
		return sRet;     
	}

	// This function creates a graph using an array of elements.  The global variable gGraphCount allows for 
	// multiple graphs to appear on one page since each graph must have a unique id.
	// NOTE: Graphing only works for 1D/2D arrays
	
	var gGraphCount = 0;
  
	function GetArrayGraph(valueNodes,nMax,bDoDecimation, graphArrayObj, sDataLayout, sDataOrientation, flattenedStructure, arrayTable)
	{
		var sRet = "";
		var sArray = "";
		var inc = 1;
		var n = 0;
		var i = 0;
		var valueNode = valueNodes.item(0);
		var colBasedDecimate = false;
		var nMaxRowsToDisplay = 0;
		var nMaxColsToDisplay = 0;
		
		if (!flattenedStructure)
			sRet += "<td valign='top' style='width:" + gSecondColumnWidth + "%;border-color:" + gTableBorderColor + "; background-color:" + gValueBgColor + "; white-space:nowrap;'><span style='font-size:82%;'>";
		else
			sRet += "<td class='ReportHeader' style='white-space:nowrap;'><b>";
		if(graphArrayObj.Dimensions == 2)
		{
			if (sDataOrientation.toLowerCase() == "column based")
				colBasedDecimate = true;
			nMaxRowsToDisplay = graphArrayObj.NumberOfGraphs;
			nMaxColsToDisplay = graphArrayObj.NumberOfColPlots;
			
			if(gArrayMeasurementFilter==1 || gArrayMeasurementFilter==3) // "Include upto max" or "Decimate if larger than max"
			{
				if(colBasedDecimate && graphArrayObj.NumberOfGraphs > gArrayMeasurementMax)
				{
					inc = (bDoDecimation)? Math.floor(graphArrayObj.NumberOfGraphs/gArrayMeasurementMax):1;
					nMaxRowsToDisplay = gArrayMeasurementMax;
				}
				else if(!colBasedDecimate && graphArrayObj.NumberOfColPlots > gArrayMeasurementMax)
				{
					inc = (bDoDecimation)? Math.floor(graphArrayObj.NumberOfColPlots/gArrayMeasurementMax):1;
					nMaxColsToDisplay = gArrayMeasurementMax;
				}
			}
		}
		else
			inc = (bDoDecimation) ? Math.floor(valueNodes.length / nMax) : 1;
		if (inc == 0)
           inc = 1;
		
        if (graphArrayObj.Dimensions == 1)
        {
		  while (valueNode && (n < nMax))
		  {
			  graphArrayObj.AddElementToGraph(valueNode);

			  do
			  {
				  valueNode = valueNodes.nextNode();
				  i++;
			  }while (valueNode && (i < inc));
  			
			  n++;
			  i = 0;
		  }
        }
        else
        {
		  while (valueNode && (n < graphArrayObj.GraphSize))
		  {
			  graphArrayObj.AddElementToGraph(valueNode);
			  valueNode = valueNodes.nextNode();
			  n++;
		  }
        }
		
		if (valueNodes.length > 0)
		{
			sRet += "<object classid='clsid:39C3B7BF-DCEF-432B-BDB3-711F1711FA4B' id='CWGRAPH";
			sRet += gGraphCount + "' height='200' style='left: 0px; top: 0px' width='100%'> " + arrayTable +" </object>";
			sRet += "<script defer type='text/vbscript'>";
			if (graphArrayObj.Dimensions == 1)
					sRet += " Call CWGRAPH" + gGraphCount + ".PlotY(Array(" + graphArrayObj.GetGraphData(0) + "), 0, " + inc + ") \n";
			else // 2D arrays
				sRet += " Call CWGRAPH" + gGraphCount + ".Plot2DArrayData( " + graphArrayObj.Get2DArrayData(inc, colBasedDecimate, nMaxRowsToDisplay, nMaxColsToDisplay) +  ",\"" + sDataLayout + "\", \"" + sDataOrientation + "\", " +"\"True\"" + ", " + inc + ")\n";

			sRet += "</script>";
			gGraphCount++;
		}
		if (!flattenedStructure)
			sRet += "</span></td>";
		else
			sRet += "</b></td>";

		return sRet;
	}
		
	var GRAPH_ATTRIBUTES_DATALAYOUT_XPATH = "Attributes/Prop[@Name='TestStand']/Prop[@Name='DataLayout']/Value";
	var GRAPH_ATTRIBUTES_DATAORIENTATION_XPATH = "Attributes/Prop[@Name='TestStand']/Prop[@Name='DataOrientation']/Value";
    
	// This function adds an array to the report as a graph 
	function AddArrayToReportAsGraph (propNodes, propName, propLabel, nLevel, flattenedStructure, objPath, arrayTable)
	{
		var propNode = 	propNodes.item(0);
		var sRet = "";
		var nMax = 0;
		var bAddArray = true;
		var bDoDecimation = false;
		var valueNodes = propNode.selectNodes("Value");
		var dataLayoutNode = propNode.selectNodes(GRAPH_ATTRIBUTES_DATALAYOUT_XPATH);
		
		var sDataLayout  = "";
		var sDataOrientation = "";

		if(dataLayoutNode[0])
			sDataLayout = dataLayoutNode[0].text;
		if(sDataLayout.toLowerCase() == "multipley" || sDataLayout.toLowerCase() == "singlex-multipley") // DataOrientation attribute value is taken into consideration only when DataLayout attribute has a valid value
		{
			var dataOrientationNode = propNode.selectNodes(GRAPH_ATTRIBUTES_DATAORIENTATION_XPATH);
			if(dataOrientationNode[0])
				sDataOrientation = dataOrientationNode[0].text;
		}

		var graphArrayObj = new GraphArray(propNode.getAttribute("LBound"), propNode.getAttribute("HBound"));

		// Include All
		if (gArrayMeasurementFilter == 0)
			nMax = valueNodes.length;

		// Include Up To Max
		else if (gArrayMeasurementFilter == 1)
			nMax = (valueNodes.length < gArrayMeasurementMax) ? valueNodes.length : gArrayMeasurementMax;

		// Exclude If Larger Than Max
		else if (gArrayMeasurementFilter == 2)
		{
			if (valueNodes.length > gArrayMeasurementMax)
			{
				bAddArray = false;
				nMax = 0;
			}
			else
				nMax = valueNodes.length;
		}

		// Decimate If Larger Than Max
		else if (gArrayMeasurementFilter == 3)
		{
			if (valueNodes.length > gArrayMeasurementMax)
			{
				bDoDecimation = true;
				nMax = gArrayMeasurementMax;
			}
			else
				nMax = valueNodes.length;
		}

		if (gIncludeArrayMeasurement != 0)
		{
			if (bAddArray)
			{
				var sArray = GetArrayGraph (valueNodes, nMax, bDoDecimation, graphArrayObj, sDataLayout, sDataOrientation, flattenedStructure, arrayTable);

				// Add Label
				sRet += "<tr>";
				if (!flattenedStructure)
					sRet += "<td valign='top' style='border-color:" + gTableBorderColor + ";background-color:" + gLabelBgColor + ";'>";
				else
					sRet += "<td  class='ReportHeader' style='white-space:nowrap'>"
					
				if (!flattenedStructure)
				{
					sRet += "<span style='font-size:82%;color:" + gLabelBgColor + ";'>" + GetIndentationString(nLevel) + "</span>";
					if (valueNodes.length > 0)
						sRet += "<span style='font-size:82%;'>" + propLabel + graphArrayObj.SizeString + ":" + "</span>";
					else
						sRet += "<span style='font-size:82%;'>" + propLabel + "[0.." + "empty" + "]" + ":" + "</span>";
				}
				else
				{
					sRet += "<b>";
					if (valueNodes.length > 0)
						sRet += objPath + graphArrayObj.SizeString + ":";
					else
						sRet += objPath + "[0.." + "empty" + "]" + ":";
						
					sRet += "</b>";
				}
					
				sRet += "</td>\n";
				// Add Array Graph
				sRet += sArray;
				sRet += "</tr>\n";
			}
		}

		return sRet;
	}
	
	//Javascript Section 6: None

	//Javascript Section 7: Utility functions
	function GetAbsolutePath(fName) 
	{
		return gStyleSheetPathPrefix + fName; 
	}
	
	//This function return the two table columns for the module time
	function GetModuleTime(nodelist)
	{
		if (gIncludeTimes)
		{
			var node = nodelist.item(0);
			var localizedText = node ? ReturnLocalizedDecimalVal_Node(node): ""

			return "<tr><td valign='top' style='border-color:" + gTableBorderColor + ";background-color:" + gLabelBgColor + 
				";'><span style='font-size:82%;'> Module Time: </span></td><td valign='top' style='width:" + gSecondColumnWidth + "%;border-color:" + gTableBorderColor + ";background-color:" + gValueBgColor + 
				";'><span style='font-size:82%;'>" + localizedText + "</span></td></tr>\n";
		}
		else
			return "";
	}
	
	// This function first converts all back-slashes into forward-slashes and then
	// removes the file name part of the input file path
	function GetFolderPath(sFilePath)
	{
		var sConvertedFilePath;
		var index = sFilePath.indexOf("\\");
		if (index == -1)
			sConvertedFilePath = sFilePath;
		else
		{
			sConvertedFilePath = "";
			do
			{
				sConvertedFilePath += sFilePath.substring(0,index) + "/";
				sFilePath = sFilePath.substring(index+1,sFilePath.length);
				index = sFilePath.indexOf("\\");
			}
			while (index != -1);
			sConvertedFilePath += sFilePath;
		}

		var sFolderPath = "";

		index = sConvertedFilePath.lastIndexOf("/");
		if (index != -1)
			sFolderPath = sConvertedFilePath.substring(0,index) + "/";

		return sFolderPath;
	}

	//This function return the list item for the total time
	function GetTotalTimeInHHMMSSFormat(nodelist)
	{
		if (gIncludeTimes)
		{
			var node = nodelist.item(0);
			var text = node ? ReturnLocalizedDecimalVal_Node(node): "";
			var time = new Date(1970,0,1);
			time.setSeconds(text);
			var totalSec = time.toTimeString().substr(0,8);
			
			if(text > 86399)
				totalSec = Math.floor((time - Date.parse("1/1/70")) / 3600000) + totalSec.substr(2);
			
			return "<tr><td class='ReportHeader'><b> Execution Time: </b></td><td class='ReportHeader'><b>" + ((text == '') ? "N/a" : totalSec) + "</b></td></tr>\n";	
		}
		else
			return "";
	}

	function ResetBlockLevel()
	{
		SetIndentationLevel(GetIndentationLevel() - GetBlockLevel());
		SetBlockLevel(0);
		return "";
	}
	
	// This function returns the serial number of the input node or returns NONE
	function GetSerialNumber(nodelist)
	{
		var node = nodelist.item(0);
		var text = node ? node.text : "";

		return (text == "") ? "NONE" : text;
	}

	// This function returns the Id of the input result node
	function GetResultId(nodelist)
	{
		var node = nodelist.item(0);
		var idNode = node.parentNode.selectSingleNode("Prop[@Name='Id']");

		if (idNode != null)
			return idNode.selectSingleNode("Value").text;
		else
			return "";
	}
	
	// This function returns the loop index text or null if LoopIndex isnt found
	function GetLoopIndex(nodelist)
	{
		var node = nodelist.item(0);
		var valueNode = node.parentNode.selectSingleNode("Prop[@Name='LoopIndex']/Value");

		if (valueNode != null)
			return " (Loop Index: " + valueNode.text + ")";
		else
			return "";
	}
	
	// This function checks if it is a flow control step or not
	function IsNotFlowControlStep(nodelist)
	{
		var node = nodelist.item(0);
		var stepType = node.selectSingleNode("Prop[@Name='TS']/Prop[@Name='StepType']/Value");
		var stepTypeText = stepType.text;
		
		if (stepTypeText.match("NI_Flow") == "NI_Flow")
			return false;
		else 
			return true;
	}
	
	// This function returns reportText to be attached to the step Name if it is a flow control step
	function GetStepNameAddition(nodelist)
	{
		var node = nodelist.item(0);
		if (node)
		{
			var stepType = node.parentNode.selectSingleNode("Prop[@Name='StepType']/Value");
			var reportText = node.parentNode.parentNode.selectSingleNode("Prop[@Name='ReportText']/Value");
			var stepTypeText = stepType? stepType.text: "";
			var reportTextVal = reportText ? reportText.text: "";
			var sRet = " ";
			if (stepTypeText.match("NI_Flow") == "NI_Flow")
			{
				if (stepTypeText.match("NI_Flow_End") == "NI_Flow_End")
				{
					reportTextVal = reportTextVal.replace("(","");
					reportTextVal = reportTextVal.replace(")","");
				}
				sRet += reportTextVal;
			}
			return sRet;
		}
		return "";
	}
	
	// This function takes an element value and 
	// 1. adds a _br_ to the output when it finds a newline character.
	// 2. Removes \r from the text
	function RemoveIllegalCharacters(nodelist)
	{
		var node = nodelist.item(0);
		var valueChildNode = node.selectSingleNode("Value");

		var text = "";
		if (valueChildNode)
		    text = valueChildNode.text;
		else
		    text = node.text;
      
		var sRet = "";
		var newLine = "<br/>";
		var index = text.indexOf("\n");
		if (index == -1)
			sRet = text;
		while(index != -1)
		{
			sRet += text.substring(0,index) + newLine;
			text = text.substring(index+1,text.length);
			index = text.indexOf("\n");
			if (index == -1)
				sRet += text;
		}
	
		var newText = sRet;
		sRet = "";
		
		if (newText != "")
		{
			var slashR = "\\r";
			index = newText.indexOf(slashR);
			if (index == -1)
				sRet = newText;
			else
			{
				while(index != -1)
				{
					sRet += newText.substring(0,index);
					newText = newText.substring(index+2, newText.length);
					index = newText.indexOf(slashR);
					if (index == -1)
						sRet += newText;
				}
			}
		}
		
		return sRet;
	}

	// This function returns either the (full) file URL or only the file name depending if storing absolute
	// or relative path to the stylesheet
	function GetLinkURL(nodelist)
	{
		var node = nodelist.item(0);
		var anchor = node.getAttribute("Anchor"); 
		var url = node.getAttribute("URL");
		var linkName = node.getAttribute("LinkName");
		var normalizedLinkName = linkName.replace(/^\s*|\s*$/g, "");
		
		if(normalizedLinkName=="")
			linkName = "NONE";
		
		var sRet = "<a"; 
		
		if (anchor != "")
			sRet += " href = \"" +  url + "#" + anchor + "\" ";
			
		sRet += ">" +  linkName + "</a>";
		
		return sRet;
	}

	//This method checks the condition to see if the property object needs to be added to the report
	function AddPropertyToReport(propnodes, bAddPropertyToReport, bIncludeMeasurement, bIncludeLimits)
	{
		var prop = propnodes.item(0);
		var propFlags = prop.getAttribute('Flags');
		var bIncludeInReport = ((propFlags & 0x2000) == 0x2000);
		var bIsMeasurementValue = ((propFlags & 0x0400) == 0x0400);
		var bIsLimitValue = ((propFlags & 0x1000) == 0x1000);
		
		if((bAddPropertyToReport || bIncludeInReport) && 
				!((bIsMeasurementValue && !(bIncludeMeasurement == 'True')) || (bIsLimitValue && !(bIncludeLimits == 'True'))) )
			return true
		else
			return false;
	}
	
	function CheckIfIncludeInReportIsPresentForAttributes(propNodes, reportOptions)
	{
		var count = propNodes.length;
		var i=0;
		var includeInReport = false;
		var arrayMeasurementFilter = -1;
		var arrayMeasurementMax = -1;
		
		for( i = 0; i < count; ++i)
		{
			var propType = propNodes.item(i).getAttribute('Type');
			var noOfChildNodes = GetChildNodesCount(propNodes.item(i));
			if ((propType != 'Obj') || (noOfChildNodes != 0))
			{	
				var computeFlags = true;
				if (propType == 'Array')
				{
					if (arrayMeasurementFilter == -1)
					{
						arrayMeasurementFilter = ConvertToDecimalValue(reportOptions.item(0).selectSingleNode("Prop[@Name = 'ArrayMeasurementFilter']/Value").text);
						arrayMeasurementMax = ConvertToDecimalValue(reportOptions.item(0).selectSingleNode("Prop[@Name = 'ArrayMeasurementMax']/Value").text);
					} 
					// A value of 2 specifies that the options is "Exclude If Larger Than Max"
					if (arrayMeasurementFilter == 2 && noOfChildNodes > arrayMeasurementMax)
						computeFlags = false;
				}
				
				if (computeFlags)
				{
					var propFlag = propNodes.item(i).getAttribute('Flags');
					if ((propFlag & 0x2000) == 0x2000)
					{ 
						includeInReport = true;
						break;
					}
				}
			}
		}
		return includeInReport;
	}
	
	//The DOM object property node.childNodes displays 2 kinds of behavior:
	//1. Considers empty space or new line as a text child node - seen in Firefox, IE9 and most other browsers.
	//2. Does not consider empty space or new line as a text node - seen in IE8 and lower versions of IE.
	//Hence a custom method to count the number of child nodes based on the type of node.
	function GetChildNodesCount(propNode)
	{
		var noOfChildNodes = 0;
		var childNode = propNode.childNodes[0];
		while(childNode)
		{
			if(childNode.nodeType == 1) // Value 1 denotes an element node
				noOfChildNodes++;
			childNode = childNode.nextSibling;
		}
		return noOfChildNodes;
	}
	
	//This method checks whether the Graphcontrol is installed and sets a global XSLT variable accordingly
	function IsGraphControlInstalled()
	{
		var haveGraphControl = 0;
		try
		{
			var xObj = new ActiveXObject("TsGraphControl2.GraphControl2");
			haveGraphControl = (xObj != null) ? 1 : 0;
		}
		catch(ex)
		{
			haveGraphControl = 0;
		}
		return haveGraphControl;
	}
	
	//This method strips the numeric value off its extra characters found in the numeric format and returns the actual value in decimal format.
	function ConvertToDecimalValue(val)
	{
		val = val.substring(0,val.lastIndexOf(gNumericFormatSuffix)); // removing any suffix added when customizing numeric format
			if (gNumericFormatRadix == 8)
			{
				val = val.substring(2);
			}
			else if (gNumericFormatRadix == 2)
			{
				var indexOfRadix = val.toLowerCase().indexOf("0b");
				val = val.substring(indexOfRadix != -1 ? indexOfRadix + 2 : 0);
			}
		return parseInt(val , gNumericFormatRadix);
	}
	
	//This method returns true if the numeric format is decimal, integer, unsignedInteger, float
	function IsOfDecimalFormat(formatString)
	{
		var result = "false";
		var formatSpecifierIndex = formatString.search(/[diuxobefg]/i);
		var formatSpecifier = formatString.charAt(formatSpecifierIndex);
		var numericFormatSuffix = formatString.substring(formatSpecifierIndex+1);
		if(formatSpecifier.search(/[guifde]/i) == 0 && numericFormatSuffix=="")
			result = "true";
		return result;
	}
	
	// Global variable to hold the value returned by parseInt for -1 in non-decimal formats
	var gMinusOneForNonDecimalFormats = 4294967295;
	
	function IsValueMinusOne(val)
	{
		var returnVal = false;
		val = ConvertToDecimalValue(val);
		if(val == -1 || val == gMinusOneForNonDecimalFormats)
			returnVal = true;
		return returnVal;
	}

	//Javascript Section 8: Functions Support for expand and collapse
	// This function creates an Id string to be used for ID attributes
	var gIdCount = 0;
	function GetIdFromNode(node,val)
	{
		var status = node.selectSingleNode("Prop/Prop[@Name='Status']/Value");

		if (val == "i")
			gIdCount++;
		if (status != null)
			return status.text + "Element" + gIdCount + val;
		else
		{
			status = node.selectSingleNode("Prop[@Name='Status']/Value");
			if (status != null)
				return status.text + "Element" + gIdCount + val;
			else
				return node.nodeName + "Element" + gIdCount + val;
		}
	}
	
	function GetId(nodelist,val)
	{
		return GetIdFromNode(nodelist.item(0),val);
	}
	
	// This function returns the style value for a div, depending on the step result status
	function GetDIVStyleFromNode(node)
	{
		var statusNode = node.selectSingleNode("Prop[@Name='Status']/Value");
		var status = (statusNode == null) ? "" : statusNode .text;

		if ((status == "Failed") || (status == "Error"))
			return "display:";
		else
			return "display:none";
	}
	
	function GetDIVStyle(nodelist)
	{
		return GetDIVStyleFromNode(nodelist.item(0));
	}
	
	// This function returns the IMG text for the input StepResult
	function GetStepResultImageFromNode(node)
	{
		var statusNode = node.selectSingleNode("Prop[@Name='Status']/Value");
		var status = (statusNode == null) ? "" : statusNode .text;
		var id = GetIdFromNode(node,"i");
		var imgfile;
		var imgsrc;

		if (status == "Passed")
			imgfile = "plusPassed.gif";
		else if (status == "Done")
			imgfile = "plusDone.gif";
		else if (status == "Failed")
			imgfile = "minusFailed.gif";
		else if (status == "Error")
			imgfile = "minusError.gif";
		else if (status == "Terminated")
			imgfile = "plusTerminated.gif";
		else if (status == "Running")
			imgfile = "plusRunning.gif";
		else
			imgfile = "plusSkipped.gif";

		imgsrc = GetAbsolutePath(imgfile);

		return "<img align='middle' style='cursor:hand;padding:0px;margin-left:" + (GetIndentationLevel() * gIndentationWidth).toString(10) + "px;' name='StepResult' class='StepResult' alt='Expand/Collapse' " + "src='" + imgsrc + "'" + "id='" + id + "'" + "> ";
	}
	
	function GetStepResultImage(nodelist)
	{
		return GetStepResultImageFromNode(nodelist.item(0));
	}
	
	function GetExpandAllImage()
	{
		var imgsrc = GetAbsolutePath("button_expand.gif");
		return "<img name='ExpandCollapseAll' class='ExpandCollapseAll' width='26px' height='28px' border='0' alt='Expand/Collapse All' style='cursor:hand' " + "src='" + imgsrc + "'/> ";
	}
		
	//JavaScript Section 9: Functions to support report filtering
	//Global variable to switch ON/OFF report filtering.	
	var gEnableResultFiltering = false;
	function SetEnableResultFiltering(enableResultFiltering)
	{
		gEnableResultFiltering = enableResultFiltering == 1 ?  true : false;
		return "";
	}
  
	//Function is called when filtering certain steps from the report being displayed
	//Returns true if a new table should be created
	function IsTableCreatedForSequence(nodeList)
	{
		var count = nodeList.length;
		var i = 0;
		
		for ( i = 0 ; i < count; ++i)
		{
			if (CheckIfStepSatisfiesFilteringCondition_node(nodeList.item(i)))
				return true;
		}
		return false;
	}
	
	function CheckIfStepSatisfiesFilteringCondition(nodeList)
	{
		var node = nodeList.item(0);
		return CheckIfStepSatisfiesFilteringCondition_node(node);
	}

	function CheckIfStepSatisfiesFilteringCondition_node(node)
	{
		//ADD_STEP_FILTERING_CONDITION	
		//Modify the filtering condition here to filter steps shown the report.

		var filteringCondition = node.selectSingleNode("Prop[@Name='Status']/Value");
		if (filteringCondition.text == 'Passed')
			return true;
		else
		  return false;
	}
		]]></msxsl:script>
	<xsl:output method="html" indent="no" omit-xml-declaration="yes" doctype-public="-//W3C//DTD HTML 4.01 Transitional//EN" media-type="text/html"/>
	
	<!-- A global variable to hold the sequence file name to be displayed in critical stack in case the sequence file is not saved. -->
	<xsl:variable name="gUnsavedSeqFileName">
		<xsl:text>Unsaved Sequence File</xsl:text>
	</xsl:variable>
	<!-- a variable to keep track of whether the required Graph control is installed on the system -->
	<xsl:variable name="gGraphControlInstalled" select="user:IsGraphControlInstalled()"/>
	<!-- a constant which decides the width the of the second column in the table-->
	<xsl:variable name="gSecondColumnWidth" select="37"/>
	<!--A variable which gets the localized decimal point and uses it to replace the decimal point in numeric values. The decimal point is localized only if the UseLocalizedDecimalPoint report option is set to true-->
	<xsl:variable name="gLocalizedDecimalPoint" select="vb_user:GetLocalizedDecimalPoint()"/>
	<xsl:variable name="gEnableResultFiltering">0</xsl:variable>
	<!-- XSLT Section 1 Initiate the creation of the html page	-->
	<xsl:template match="/">
		<html>
			<head>
				<title>XML Report</title>
				<style type="text/css">
					td{border-width:1px;border-style:solid;}
					td.ReportHeader{border-style:none;}
					.child {display:none}
					div{padding-top:0.3em; padding-bottom:0.3em;}
					h5{white-space:nowrap;}

					h4{margin-bottom:0px;padding-bottom:0px;white-space:nowrap;}
					hr{width:87%;height:2px;text-align:left;margin-left:0;color:lightgray;background-color:lightgray;border-style:groove;}
					body { margin: 0px; }
					@import url(http://fonts.googleapis.com/css?family=Open+Sans);
					.header {margin:0px; margin-bottom: 10px; background: #F2F2F2;}
					.header .centered { max-width: 970px; min-width: 600px; margin-left: auto; margin-right:auto; margin-top: 0px; margin-bottom:0px; }
					.centered img { display: block; margin-left: auto; margin-right: auto; border: 10px solid #F2F2F2; }
					.retest { margin: 6px; }
					.UUTreport { margin: 6px; }

				</style>
				<xsl:if test="//Report">
					<xsl:value-of select="user:InitStylesheetPath(//Report/Prop[@Name='ReportOptions'])"/>
					<xsl:value-of select="user:SetLocalizedDecimalPoint(vb_user:GetLocalizedDecimalPoint())"/>
					<xsl:value-of select="user:SetEnableResultFiltering(string($gEnableResultFiltering))"/>
				</xsl:if>
				<!-- XSLT Section 1.1 Javascript that will be included with the generated html file to support the expand/collapse functionality-->
				<script type="text/javascript">
					var minusFailedImg = "<xsl:value-of select="user:GetAbsolutePath('minusFailed.gif')"/>";
					var minusErrorImg = "<xsl:value-of select="user:GetAbsolutePath('minusError.gif')"/>";
					var minusPassedImg = "<xsl:value-of select="user:GetAbsolutePath('minusPassed.gif')"/>";
					var minusTerminatedImg = "<xsl:value-of select="user:GetAbsolutePath('minusTerminated.gif')"/>";
					var minusDoneImg = "<xsl:value-of select="user:GetAbsolutePath('minusDone.gif')"/>";
					var minusRunningImg = "<xsl:value-of select="user:GetAbsolutePath('minusRunning.gif')"/>";
					var minusSkippedImg = "<xsl:value-of select="user:GetAbsolutePath('minusSkipped.gif')"/>";
					var plusFailedImg = "<xsl:value-of select="user:GetAbsolutePath('plusFailed.gif')"/>";
					var plusErrorImg = "<xsl:value-of select="user:GetAbsolutePath('plusError.gif')"/>";
					var plusPassedImg = "<xsl:value-of select="user:GetAbsolutePath('plusPassed.gif')"/>";
					var plusTerminatedImg = "<xsl:value-of select="user:GetAbsolutePath('plusTerminated.gif')"/>";
					var plusDoneImg = "<xsl:value-of select="user:GetAbsolutePath('plusDone.gif')"/>";
					var plusRunningImg = "<xsl:value-of select="user:GetAbsolutePath('plusRunning.gif')"/>";
					var plusSkippedImg = "<xsl:value-of select="user:GetAbsolutePath('plusSkipped.gif')"/>";

					var collapseImg = "<xsl:value-of select="user:GetAbsolutePath('button_collapse.gif')"/>";
					var expandImg = "<xsl:value-of select="user:GetAbsolutePath('button_expand.gif')"/>";

					var gIsExpanded = false;
					var docImages = document.images;

					function ExpandOrCollapseStepResult (srcElement, doECAll, isExpanded)
					{
						var srcId;
						var targetId, targetElement;
						var status;
						var index;

						srcId =  srcElement.id.substr(0,  srcElement.id.length-1);
						index = srcId.indexOf("Element");
						status = srcId.substr(0,index);
						targetId = srcId + "s";
						targetElement = document.all(targetId);

						if ((doECAll &amp;&amp; isExpanded) || (!doECAll &amp;&amp; (targetElement.style.display == "none")))
						{
							targetElement.style.display = "";
							if (status == "Failed")
								srcElement.src = minusFailedImg;
							else if (status == "Error")
								srcElement.src = minusErrorImg;
							else if (status == "Passed")
								srcElement.src = minusPassedImg;
							else if (status == "Terminated")
								srcElement.src = minusTerminatedImg;
							else if (status == "Done")
								srcElement.src = minusDoneImg;
							else if (status == "Running")
								srcElement.src = minusRunningImg;
							else
								srcElement.src = minusSkippedImg;
						}
						else
						{
							targetElement.style.display = "none";
							if (status == "Failed")
								srcElement.src = plusFailedImg;
							else if (status == "Error")
								srcElement.src = plusErrorImg;
							else if (status == "Passed")
								srcElement.src = plusPassedImg;
							else if (status == "Terminated")
								srcElement.src = plusTerminatedImg;
							else if (status == "Done")
								srcElement.src = plusDoneImg;
							else if (status == "Running")
								srcElement.src = plusRunningImg;
							else
								srcElement.src = plusSkippedImg;
						}
					}

					function ExpandOrCollapseAll (srcElement)
					{
						gIsExpanded = !gIsExpanded;

						srcElement.src = (gIsExpanded) ? collapseImg : expandImg;

						for (i = 0; i &lt; docImages.length; i++)
							if (docImages[i].className == "StepResult")
								ExpandOrCollapseStepResult(docImages[i], true, gIsExpanded);
					}

					// Expands the sequence hierarchy on clicking on the step link in critical failure stack table 
					function ExpandTable ()
					{
						var anchorElement = window.event.target || window.event.srcElement;		
						var anchorHref = anchorElement.href;
						var indexOfHash = anchorHref.lastIndexOf('#');
						var id = anchorHref.substring(indexOfHash + 1);
						var tableElement = (document.getElementsByName(id))[0];
						var parentElement = tableElement.parentNode;
						var imageElement;
						var index;
						
						while(parentElement.tagName != "BODY")
						{
							if(parentElement.tagName=="DIV" &amp;&amp; parentElement.className ==  "StepResult")
							{
								id = parentElement.id;
								index = id.lastIndexOf('s');
								id = id.substr(0, index) + 'i' + id.substr(index + 1);
								imageElement = document.getElementById(id);
								ExpandOrCollapseStepResult(imageElement, true, true);
							}
							parentElement = parentElement.parentNode;
						}
					}
					
					function OnClick()
					{
						var srcElement = window.event.srcElement;
						if (srcElement.className == "ExpandCollapseAll")
							ExpandOrCollapseAll(srcElement);
						else if (srcElement.className == "StepResult")
							ExpandOrCollapseStepResult(srcElement, false, false);
					}

					with (document)
					{
						onclick = OnClick;
					}
				</script>
			</head>
			<body style="font-family:verdana;font-size:100%;">
				<div class="header">
					<div class="centered">
						<img src="http://www.rtlogic.com/~/media/images/logos/rtlogic-logo.png" border="0" align="center" />
					</div>
				</div>
				<!-- ADD_HEADER_INFO Section to add some header Text/Image to the entire report
					<img src = 'c:\Images\CompanyLogo.jpg'/>
					<span style="font-size:1.13em;color:#003366;">Computer Motherboard Test</span>
					<br/>
				-->
				<xsl:apply-templates select="//retest"/>
				<xsl:if test="//Report">
					<xsl:value-of select="user:GetExpandAllImage()" disable-output-escaping="yes"/>
					<b> Expand/Collapse All Step Results</b>
					<xsl:apply-templates select="//Report"/>
				</xsl:if>
				<!-- ADD_FOOTER_INFO Section to add some footer Text/Image to the entire report
					<span style="font-family:arial;color:#003366;">TestStand Generated Report</span>
				-->
			</body>
		</html>
	</xsl:template>

	<!-- XSLT Section 1.1: Templates to process Retest Report -->
	<xsl:template match="retest">
		<div style="padding:4px; border: 1px solid black;font-family: 'Open Sans', Arial, 'sans-serif'; font-size: 11pt;" class="retest">
			<h2 style="margin:none;">Update to UUT Test Report</h2>
			<p><b>Note:</b> This PCA has been manually retested by an RT Logic Technician. The manual test results are shown in the orange box. The original test data is included below.</p>
			<div style="padding: 12px; border: 1px solid #aaa; background-color: #FFF8CC;">
				<xsl:apply-templates />
			</div>
		</div>
	</xsl:template>
	
	<xsl:template match="info">
			<table style="border: 1px solid black; padding: 5px; background-color: #FFFDF0;" width="310px" >
				<tr>
					<td>Technician:</td>
					<td><xsl:value-of select="technician"/> </td>
				</tr>
				<tr>
					<td>UUT Serial Number:</td>
					<td><xsl:value-of select="unit/serial"/></td>
				</tr>
				<tr>
					<td>Date Retested:</td>
					<td><xsl:value-of select="date"/></td>
				</tr>
			</table>
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="unit">
		<xsl:apply-templates />
	</xsl:template>	
	
	<xsl:template match="technician">
	</xsl:template>
	
	<xsl:template match="date">
	</xsl:template>
	
	<xsl:template match="serial">
	</xsl:template>
	
	<xsl:template match="results">
		<table style="margin-top: 7px;">
			<tr>
				<td>
					<h2>Test Data</h2>
				</td>
			</tr>
			<tr>
				<td style="padding: 5px;">Reason for Retest:</td><td style="border: 2px solid #48ACD4; background-color: #F2FBFF; padding: 5px;"><xsl:value-of select="reason"/></td>
			</tr>
			<tr>
				<td style="padding: 5px;">Test Equipment Make and Model:</td><td style="border: 2px solid #48ACD4; background-color: #F2FBFF; padding: 5px;"><xsl:value-of select="test-equipment"/></td>
			</tr>
			<tr>
				<td style="padding: 5px;">Results:</td><td style="border: 2px solid #48ACD4; background-color: #F2FBFF; padding: 5px;"><xsl:value-of select="comment-box"/></td>
			</tr>
		</table>
	</xsl:template>
	
	<xsl:template match="reason">
	</xsl:template>	

	<xsl:template match="test-equipment">
	</xsl:template>	
	
	<xsl:template match="comment-box">
	</xsl:template>	

	
	<!-- XSLT Section 2 Templates to process UUT report	-->
	<!-- XSLT Section 2.1 Templates to process <Report> tag of type 'UUT'	-->
	<xsl:template match="Report[@Type='UUT']">
		<xsl:value-of select="user:InitNumericFormatRadix(Prop[@Name='ReportOptions'])"/>
		<xsl:value-of select="user:InitFlagGlobalVariables(Prop[@Name='ReportOptions'])"/>
		<xsl:value-of select="user:InitColorGlobalVariables(Prop[@Name='ReportOptions']/Prop[@Name='Colors'])"/>
		<xsl:value-of select="user:InitLoopArray(.)"/>
		<xsl:value-of select="user:InitBlockLevelArray()"/>
		<xsl:value-of select="user:InitLoopingInfoArray()"/>
		<xsl:variable name="reportOptions" select="Prop[@Name='ReportOptions']"/>
		<xsl:variable name="labelBgColor" select="$reportOptions/Prop[@Name = 'Colors']/Prop[@Name = 'LabelBg']/Value"/>
		<xsl:variable name="valueBgColor" select="$reportOptions/Prop[@Name = 'Colors']/Prop[@Name = 'ValueBg']/Value"/>
		<a>
			<xsl:attribute name="name"><xsl:value-of select="@Link"/></xsl:attribute>
		</a>
		<h3>
			<xsl:value-of select="@Title"/>
		</h3>
		<table style="width:70%" frame="void">
			<tbody>
				<xsl:apply-templates select="Prop[@Name='StationInfo']/Prop[@Name='StationID']"/>
				<xsl:apply-templates select="Prop[@Name='UUT']/Prop[@Name='BatchSerialNumber']"/>
				<xsl:apply-templates select="Prop[@Name='UUT']/Prop[@Name='TestSocketIndex']"/>
				<xsl:apply-templates select="Prop[@Name='UUT']/Prop[@Name='SerialNumber']"/>
				<xsl:apply-templates select="Prop[@Name='StartDate']"/>
				<xsl:apply-templates select="Prop[@Name='StartTime']"/>
				<xsl:apply-templates select="Prop[@Name='StationInfo']/Prop[@Name='LoginName']"/>
				<xsl:apply-templates select="Prop/Prop[@Name='TS']/Prop[@Name='TotalTime']">
					<xsl:with-param name="includeTimes" select="$reportOptions/Prop[@Name = 'IncludeTimes']/Value"/>
					<xsl:with-param name="useLocalizedDecimalPoint" select="$reportOptions/Prop[@Name='UseLocalizedDecimalPoint']/Value"/>
				</xsl:apply-templates>
				<tr>
					<td class="ReportHeader" style="white-space:nowrap">
						<b>
							 Number of Results: 
						</b>
					</td>
					<td class="ReportHeader">
						<b>
							<xsl:value-of select="@StepCount"/>
						</b>
					</td>
				</tr>
				<tr>
					<td class="ReportHeader" style="white-space:nowrap">
						<b>
							 UUT Result: 
						</b>
					</td>
					<td class="ReportHeader">
						<b>
							<span>
								<xsl:attribute name="style">color:<xsl:call-template name="GetStatusColor">
										<xsl:with-param name="colors" select="$reportOptions/Prop[@Name = 'Colors']"/>
										<xsl:with-param name="status" select="@UUTResult"/>	
									</xsl:call-template></xsl:attribute>
								<xsl:value-of select="@UUTResult"/>
							</span>
						</b>
						<xsl:if test="ErrorText">
							, <xsl:value-of disable-output-escaping="yes" select="user:RemoveIllegalCharacters(ErrorText)"/>
						</xsl:if>
					</td>
				</tr>
				<xsl:apply-templates select="Prop[@Name='UUT']/Prop[@Name='PartNumber']"/>
				<xsl:apply-templates select="Prop[@Name='TSRData']/Prop[@Name='TSRFileName']"/>
				<xsl:apply-templates select="Prop[@Name='TSRData']/Prop[@Name='TSRFileID']"/>
				<xsl:apply-templates select="Prop[@Name='TSRData']/Prop[@Name='TSRFileClosed']"/>
        
        <xsl:apply-templates select="Prop[@Name='UUT']/Prop[@Name='AdditionalData']">
          <xsl:with-param name="reportOptions" select="$reportOptions"/>
          <xsl:with-param name="labelBgColor" select="$labelBgColor"/>
          <xsl:with-param name="valueBgColor" select="$valueBgColor"/>
        </xsl:apply-templates>
        <!-- CREATE_UUTHEADER_INFO: Section to insert additional rows to UUT report header
				html to add a new row showing ReportType
				Ex:
					<tr>
						<td class="ReportHeader" style="white-space:nowrap">
							<b>
								 Type of Report:
							</b>
						</td>
						<td class="ReportHeader">
							<b>
								<xsl:value-of select="@Type"/>
							</b>
						</td>
					</tr>
				-->
				<xsl:if test="Prop[@Name='UUT']/Prop[@Name='CriticalFailureStack']/Value">
					<tr>
						<td class="ReportHeader" style="white-space:nowrap">
							<b>
								 Failure Chain: 
							</b>
						</td>
					</tr>
				</xsl:if>
			</tbody>
		</table>
		<br/>
		<xsl:apply-templates select="Prop[@Name='UUT']/Prop[@Name='CriticalFailureStack']">
			<xsl:with-param name="tableBorderColor" select="$reportOptions/Prop[@Name = 'Colors']/Prop[@Name = 'TableBorder']/Value"/>
			<xsl:with-param name="failureStackLabelBgColor" select="$reportOptions/Prop[@Name = 'Colors']/Prop[@Name = 'FailureStackLabelBg']/Value"/>
			<xsl:with-param name="failureStackValueBgColor" select="$reportOptions/Prop[@Name = 'Colors']/Prop[@Name = 'FailureStackValueBg']/Value"/>
		</xsl:apply-templates>
		<hr>
			<xsl:attribute name="style">border-width:0;width:50%;height:3px;text-align:left;margin-left:0;color:<xsl:value-of select="$reportOptions/Prop[@Name = 'Colors']/Prop[@Name = 'HeaderSeparator']/Value" disable-output-escaping="no"/>;background-color:<xsl:value-of select="$reportOptions/Prop[@Name = 'Colors']/Prop[@Name = 'HeaderSeparator']/Value" disable-output-escaping="no"/>;</xsl:attribute>
		</hr>
		<xsl:if test="$gEnableResultFiltering = 0 or user:IsTableCreatedForSequence(Prop/Prop[@Name='TS']/Prop[@Name='SequenceCall']/Prop[@Name = 'ResultList']/Value[@ID]/Prop[@Type = 'TEResult']) = 'true'">
			<xsl:choose>
				<xsl:when test="not(Prop/Prop[@Name='TS']/Prop[@Name='SequenceCall']/Prop[@Name='ResultList'])">
					<xsl:value-of select="user:SetIndentationLevel(user:GetIndentationLevel() + 1)"/>
					<h5>
						<xsl:attribute name="style">margin-left:<xsl:value-of select="user:GetIndentationWidth()"/>px;</xsl:attribute>
						Begin Sequence: <xsl:value-of select="Prop/Prop[@Name='TS']/Prop[@Name='SequenceCall']/Prop[@Name='Sequence']/Value"/>
						<br/>(<xsl:apply-templates select="Prop/Prop[@Name='TS']/Prop[@Name='SequenceCall']/Prop[@Name='SequenceFile']"/>)
					</h5>
					<h5>
						<xsl:attribute name="style">margin-left:<xsl:value-of select="(user:GetIndentationLevel() + 1) * user:GetIndentationWidth()"/>px;</xsl:attribute>No Sequence Results Found</h5>
					<h5>
						<xsl:attribute name="style">margin-left:<xsl:value-of select="user:GetIndentationWidth()"/>px;</xsl:attribute>
						End Sequence: <xsl:value-of select="Prop/Prop[@Name='TS']/Prop[@Name='SequenceCall']/Prop[@Name='Sequence']/Value"/>
					</h5>
					<xsl:value-of select="user:SetIndentationLevel(user:GetIndentationLevel() - 1)"/>
				</xsl:when>
				<xsl:when test="count(Prop/Prop[@Name='TS']/Prop[@Name='SequenceCall']/Prop[@Name='ResultList']/Value) = 0">
					<h5>
						<xsl:attribute name="style">margin-left:<xsl:value-of select="user:GetIndentationLevel() * user:GetIndentationWidth()"/>px;</xsl:attribute>No Sequence Results Found</h5>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="user:SetIndentationLevel(user:GetIndentationLevel() + 1)"/>
					<h5>
						<xsl:attribute name="style">margin-left:<xsl:value-of select="user:GetIndentationWidth()"/>px;</xsl:attribute>
						Begin Sequence: <xsl:value-of select="Prop/Prop[@Name='TS']/Prop[@Name='SequenceCall']/Prop[@Name='Sequence']/Value"/>
						<br/>(<xsl:apply-templates select="Prop/Prop[@Name='TS']/Prop[@Name='SequenceCall']/Prop[@Name='SequenceFile']"/>)
					</h5>
					<xsl:apply-templates select="Prop/Prop[@Name='TS']/Prop[@Name='SequenceCall']/Prop[@Name='ResultList']">
						<xsl:with-param name="reportOptions" select="$reportOptions"/>
						<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
						<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
					</xsl:apply-templates>
					<xsl:value-of disable-output-escaping="yes" select="user:ResetBlockLevel()"/>
					<h5>
						<xsl:attribute name="style">margin-left:<xsl:value-of select="user:GetIndentationWidth()"/>px;</xsl:attribute>
						End Sequence: <xsl:value-of select="Prop/Prop[@Name='TS']/Prop[@Name='SequenceCall']/Prop[@Name='Sequence']/Value"/>
					</h5>
					<xsl:value-of select="user:SetIndentationLevel(user:GetIndentationLevel() - 1)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
		<h3>End UUT Report</h3>
		<hr>
			<xsl:attribute name="style">border-width:0;width:90%;height:5px;color:<xsl:value-of select="$reportOptions/Prop[@Name = 'Colors']/Prop[@Name = 'UUTSeparator']/Value" disable-output-escaping="no"/>;background-color:<xsl:value-of select="$reportOptions/Prop[@Name = 'Colors']/Prop[@Name = 'UUTSeparator']/Value" disable-output-escaping="no"/>;</xsl:attribute>
		</hr>
	</xsl:template>
	<!-- XSLT Section 2.2 Templates to get data to be added into the UUT report header	-->
	<xsl:template match="Prop[@Name='BatchSerialNumber']">
		<xsl:if test="Value != ''">
			<tr>
				<td class="ReportHeader" style="white-space:nowrap">
					<b>
						 Batch Serial Number: 
					</b>
				</td>
				<td class="ReportHeader">
					<b>
						<xsl:value-of select="Value"/>
					</b>
				</td>
			</tr>
		</xsl:if>
	</xsl:template>
	<xsl:template match="Prop[@Name='TestSocketIndex']">
		<xsl:variable name="isMinusOne">
			<xsl:value-of select="user:IsValueMinusOne(string(Value))"/>
		</xsl:variable>
		<xsl:if test="string($isMinusOne) = string(false())">
			<tr>
				<td class="ReportHeader" style="white-space:nowrap">
					<b>
							 Test Socket Index: 
						</b>
				</td>
				<td class="ReportHeader">
					<b>
						<xsl:value-of select="Value"/>
					</b>
				</td>
			</tr> 
		</xsl:if>
	</xsl:template>
	<xsl:template match="Prop[@Name='TSRFileName']">
		<xsl:if test="Value != ''">
			<tr>
				<td class="ReportHeader" style="white-space:nowrap">
					<b>
						 TSR File Name: 
					</b>
				</td>
				<td class="ReportHeader">
					<b>
						<xsl:value-of select="Value"/>
					</b>
				</td>
			</tr>
		</xsl:if>
	</xsl:template>
	<xsl:template match="Prop[@Name='TSRFileID']">
		<xsl:if test="Value != ''">
			<tr>
				<td class="ReportHeader" style="white-space:nowrap">
					<b>
						 TSR File ID: 
					</b>
				</td>
				<td class="ReportHeader">
					<b>
						<xsl:value-of select="Value"/>
					</b>
				</td>
			</tr>
		</xsl:if>
	</xsl:template>	
	<xsl:template match="Prop[@Name='TSRFileClosed']">
		<xsl:if test="Value != ''">
			<tr>
				<td class="ReportHeader" style="white-space:nowrap">
					<b>
						 TSR File Closed: 
					</b>
				</td>
				<td class="ReportHeader" style="white-space:normal">
					<b>
						<xsl:choose>
							<xsl:when test="Value = 'True'">OK</xsl:when>
							<xsl:otherwise>The .tsr file was not closed normally when written. This can indicate that the testing process was interrupted or aborted.</xsl:otherwise>
						</xsl:choose>
					</b>
				</td>
			</tr>
		</xsl:if>
	</xsl:template>
	<xsl:template match="Prop[@Name='PartNumber']">
		<xsl:if test="Value != ''">
			<tr>
				<td class="ReportHeader" style="white-space:nowrap">
					<b>
						 Part Number: 
					</b>
				</td>
				<td class="ReportHeader">
					<b>
						<xsl:value-of select="Value"/>
					</b>
				</td>
			</tr>
		</xsl:if>
	</xsl:template>
  <xsl:template match="Prop[@Name='AdditionalData']">
    <xsl:param name="reportOptions"/>
    <xsl:param name="labelBgColor"/>
    <xsl:param name="valueBgColor"/>
    <xsl:if test="count(./Prop) > 0 and user:CheckIfIncludeInReportIsPresentForAttributes(. | .//Prop[@Flags and @Type], $reportOptions)">
      <xsl:call-template name="PutFlaggedValuesInReport">
        <xsl:with-param name="propNodes" select="."/>
        <xsl:with-param name="parentPropName" select="''"/>
        <xsl:with-param name="bAddPropertyToReport" select="0"/>
        <xsl:with-param name="nLevel" select="0"/>
        <xsl:with-param name="reportOptions" select="$reportOptions"/>
        <xsl:with-param name="labelBgColor" select="$labelBgColor"/>
        <xsl:with-param name="valueBgColor" select="$valueBgColor"/>
        <xsl:with-param name="flattenedStructure" select="true()"/>
        <xsl:with-param name="objectPath"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>
  <xsl:template match="Prop[@Name='SerialNumber']">
		<tr>
			<td class="ReportHeader" style="white-space:nowrap">
				<b>
					 Serial Number: 
				</b>
			</td>
			<td class="ReportHeader">
				<b>
					<xsl:value-of select="user:GetSerialNumber(Value)"/>
				</b>
			</td>
		</tr>
	</xsl:template>
	<!-- CHANGE_TOTAL_TIME_FORMAT : Use the following template instead of the "TotalTime" template below to get the time in Hour:Minutes:Seconds format.-->
		<xsl:template match="Prop[@Name='TotalTime']">
			<xsl:param name="includeStepResults"/>
			<xsl:param name="includeTimes"/>
			<xsl:param name="useLocalizedDecimalPoint"/>
			<xsl:value-of disable-output-escaping="yes" select="user:GetTotalTimeInHHMMSSFormat(Value)"/>
		</xsl:template>
	<!--
	<xsl:template match="Prop[@Name='TotalTime']">
		<xsl:param name="includeTimes"/>
		<xsl:param name="useLocalizedDecimalPoint"/>
		<xsl:if test="$includeTimes = 'True'">
			<tr>
				<td class="ReportHeader" style='white-space:nowrap'>
					<b>
						
							Execution Time:
						
					</b>
				</td>
				<td class="ReportHeader">
					<b>
						<xsl:choose>
							<xsl:when test="string-length(Value) &gt; 0">
								<xsl:choose>
									<xsl:when test="$useLocalizedDecimalPoint = 'True' and $gLocalizedDecimalPoint != '.'">
										<xsl:value-of select="translate(Value, '.', $gLocalizedDecimalPoint)"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="Value"/>
									</xsl:otherwise>
								</xsl:choose>
								seconds
							</xsl:when>
							<xsl:otherwise>
								N/a
							</xsl:otherwise>
						</xsl:choose>
					</b>
				</td>
			</tr>
		</xsl:if>
	</xsl:template>
	-->
	<!-- XSLT Section 2.3 Template to add header to the table that contains the report for a sequence call and call Template to handle 'TEResult'  within it. -->
	<xsl:template match="Prop[@Name='SequenceCall']">
		<xsl:param name="reportOptions"/>
		<xsl:param name="labelBgColor"/>
		<xsl:param name="valueBgColor"/>
		<xsl:if test="count(./Prop[@Name='ResultList']/Value) > 0">
			<div>
				<xsl:if test="$gEnableResultFiltering = 0 or user:IsTableCreatedForSequence(Prop[@Name = 'ResultList']/Value[@ID]/Prop[@Type = 'TEResult']) = 'true'">
					<!-- REMOVE_INDENTATION -->
					<xsl:value-of select="user:SetIndentationLevel(user:GetIndentationLevel() + 1)"/>
					<xsl:variable name="indentation" select="(user:GetIndentationLevel() + 1) * user:GetIndentationWidth() + 10"/>
					<br/>
					<h5>
						<xsl:value-of disable-output-escaping="yes" select="user:GetStepResultImage(.)"/>
						Begin Sequence: <xsl:value-of select="Prop[@Name='Sequence']/Value"/>
						<div style="padding:0px;margin-left:{$indentation}px;">
							<span style="white-space:nowrap;">
								(<xsl:apply-templates select="Prop[@Name='SequenceFile']"/>)
							</span>
						</div>
					</h5>		
					
					<div class="StepResult">
						<xsl:attribute name="id"><xsl:value-of select="user:GetId(.,'s')"/></xsl:attribute>
						<xsl:attribute name="style"><xsl:value-of select="user:GetDIVStyle(.)"/></xsl:attribute>
						<!-- REMOVE_INDENTATION -->
						<xsl:value-of select="user:SetIndentationLevel(user:GetIndentationLevel() + 1)"/>
						<xsl:if test="Prop[@Name='ResultList']">
							<xsl:value-of disable-output-escaping="yes" select="user:SetResultLevel(user:GetResultLevel()+1)"/>
							<xsl:value-of select="user:StoreCurrentLoopingLevel()"/>
							<xsl:apply-templates select="Prop[@Name='ResultList']">
								<xsl:with-param name="reportOptions" select="$reportOptions"/>
								<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
								<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
							</xsl:apply-templates>
							<xsl:value-of disable-output-escaping="yes" select="user:ResetBlockLevel()"/>
							<xsl:value-of select="user:RestoreLoopingLevel()"/>
							<!-- REMOVE_INDENTATION -->
							<xsl:value-of disable-output-escaping="yes" select="user:SetResultLevel(user:GetResultLevel()-1)"/>
						</xsl:if>
						<xsl:if test="not (Prop[@Name='ResultList'])">
							<div>
								<xsl:value-of select="user:SetIndentationLevel(user:GetIndentationLevel() + 1)"/>
								<h5>
									<xsl:attribute name="style">margin-left:<xsl:value-of select="user:GetIndentationLevel() * user:GetIndentationWidth()"/>px;</xsl:attribute>No Sequence Results Found</h5>
								<xsl:value-of select="user:SetIndentationLevel(user:GetIndentationLevel() - 1)"/>
							</div>
						</xsl:if>
						<!-- REMOVE_INDENTATION -->
						<xsl:value-of select="user:SetIndentationLevel(user:GetIndentationLevel() - 1)"/>
						<h5>
							<xsl:attribute name="style">margin-left:<xsl:value-of select="user:GetIndentationLevel() * user:GetIndentationWidth()"/>px;</xsl:attribute>
							End Sequence: <xsl:value-of select="Prop[@Name='Sequence']/Value"/>
						</h5>
					</div>
					<!-- REMOVE_INDENTATION -->
					<xsl:value-of select="user:SetIndentationLevel(user:GetIndentationLevel() - 1)"/>
				</xsl:if>
			</div>
		</xsl:if>
	</xsl:template>
	<!-- XSLT Section 2.4 Template to add sequence file path to the header of the sequence report table -->
	<xsl:template match="Prop[@Name='SequenceFile']">
		<xsl:if test="Value = ''">
			<xsl:value-of disable-output-escaping="yes" select="$gUnsavedSeqFileName"/>
		</xsl:if>
		<xsl:if test="Value != ''">
			<xsl:value-of select="Value"/>
		</xsl:if>
	</xsl:template>
	<!-- XSLT Section 2.5 Template to add step results into report -->
	<xsl:template match="Prop[@Name='ResultList']">
		<xsl:param name="reportOptions"/>
		<xsl:param name="labelBgColor"/>
		<xsl:param name="valueBgColor"/>
		<div>
			<xsl:for-each select="Value[@ID]/Prop[@Type='TEResult']">
				<!--FILTER_STEPS_START Disabling display of step results for certain categories of steps -->
				<xsl:value-of disable-output-escaping="yes" select="user:ProcessCurrentBlockLevel(.)"/>
				<xsl:if test="Prop[@Name='TS']/Prop[@Name='NumLoops']">
					<xsl:value-of disable-output-escaping="yes" select="user:BeginLoopIndices(.)"/>
				</xsl:if>
				<xsl:if test="Prop[@Name='TS']/Prop[@Name='LoopIndex']">
					<xsl:value-of disable-output-escaping="yes" select="user:TestForStartLoopIndex()"/>
				</xsl:if>
				<xsl:if test="$gEnableResultFiltering = 0 or user:CheckIfStepSatisfiesFilteringCondition(current()) = 'true' ">
					<xsl:value-of disable-output-escaping="yes" select="user:GetStepResultImage(.)"/>
					<b style="white-space:nowrap">
						<xsl:text> </xsl:text>
						<xsl:value-of select="Prop[@Name='TS']/Prop[@Name='StepName']/Value"/>
						<xsl:if test="Prop[@Name='TS']/Prop[@Name='LoopIndex']">
							(Loop Index: <xsl:value-of select="Prop[@Name='TS']/Prop[@Name='LoopIndex']/Value"/>)
						</xsl:if>
					</b>
					<br/>
					<div class="StepResult">
						<xsl:attribute name="id"><xsl:value-of select="user:GetId(.,'s')"/></xsl:attribute>
						<xsl:attribute name="style"><xsl:value-of select="user:GetDIVStyle(.)"/></xsl:attribute>
						<div>
							<table>
								<xsl:attribute name="style">width:60%;border-width:1px;border-style:solid;border-color:<xsl:value-of select="$reportOptions/Prop[@Name = 'Colors']/Prop[@Name = 'TableBorder']/Value" disable-output-escaping="no"/>;margin-left:<xsl:value-of select="(user:GetIndentationLevel() + 1) * user:GetIndentationWidth()"/>px;</xsl:attribute>
								<tbody>
									<xsl:apply-templates select="Prop[@Name='TS']/Prop[@Name='StepName']">
										<xsl:with-param name="colors" select="$reportOptions/Prop[@Name = 'Colors']"/>
									</xsl:apply-templates>
									<xsl:apply-templates select="Prop[@Name='Status']">
										<xsl:with-param name="colors" select="$reportOptions/Prop[@Name = 'Colors']"/>
									</xsl:apply-templates>
									<xsl:choose>
									<xsl:when test="Prop[@Name='Status']/Value != 'Skipped'">
										<xsl:if test="Prop[@Name='Status']/Value = 'Error'">
											<xsl:apply-templates select="Prop[@Name='Error']">
												<xsl:with-param name="reportOptions" select="$reportOptions"/>
											</xsl:apply-templates>
										</xsl:if>
										<xsl:call-template name="PutFlaggedValuesInReport">
											<xsl:with-param name="propNodes" select="Prop[@Flags]"/>
											<xsl:with-param name="parentPropName" select="''"/>
											<xsl:with-param name="bAddPropertyToReport" select="0"/>
											<xsl:with-param name="nLevel" select="0"/>
											<xsl:with-param name="reportOptions" select="$reportOptions"/>
											<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
											<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
										</xsl:call-template>
										<xsl:apply-templates select="Prop[@Name='TS']/Prop[@Name='ModuleTime']"/>
										<xsl:apply-templates select="Prop[@Name='TS']/Prop[@Name='NumLoops']">
											<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
											<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
										</xsl:apply-templates>
										<xsl:apply-templates select="Prop[@Name='TS']/Prop[@Name='NumPassed']">
											<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
											<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
										</xsl:apply-templates>
										<xsl:apply-templates select="Prop[@Name='TS']/Prop[@Name='NumFailed']">
											<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
											<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
										</xsl:apply-templates>
										<xsl:apply-templates select="Prop[@Name='TS']/Prop[@Name='EndingLoopIndex']">
											<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
											<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
											<xsl:with-param name="useLocalizedDecimalPoint" select="$reportOptions/Prop[@Name='UseLocalizedDecimalPoint']/Value"/>
										</xsl:apply-templates>
										<xsl:if test="Prop[@Name='ReportText']/Value != ''">
											<xsl:if test="user:IsNotFlowControlStep(.)">
												<xsl:apply-templates select="Prop[@Name='ReportText']">
													<xsl:with-param name="reportTextBgColor" select="$reportOptions/Prop[@Name = 'Colors']/Prop[@Name = 'ReportTextBg']/Value"/>
												</xsl:apply-templates>
											</xsl:if>
										</xsl:if>
										<xsl:apply-templates select="Prop[@Name='TS']/Prop[@Name='InteractiveExeNum']">
											<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
											<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
										</xsl:apply-templates>
										<xsl:apply-templates select="Prop[@Name='TS']/Prop[@Name='Server']">
											<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
											<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
										</xsl:apply-templates>
									</xsl:when>
									<xsl:when test="Prop[@Name='Status']/Value = 'Skipped'">
										<xsl:apply-templates select="Prop[@Name='TS']/Prop[@Name='InteractiveExeNum']">
											<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
											<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
										</xsl:apply-templates>
									</xsl:when>
									</xsl:choose>
									<!--ADD_EXTRA_ROWS: If any extra information need to be added to a step in a seperate row the user can add it here 
									Ex - to add new row containing stepId
									<tr>
										<td>
											<xsl:attribute name="style">border-color:<xsl:value-of select="$reportOptions/Prop[@Name = 'Colors']/Prop[@Name = 'TableBorder']/Value" disable-output-escaping="no"/></xsl:attribute>
											<span style='font-size:82%;'>StepID</span>
										</td>
										<td>
											<xsl:attribute name="style">border-color:<xsl:value-of select="$reportOptions/Prop[@Name = 'Colors']/Prop[@Name = 'TableBorder']/Value" disable-output-escaping="no"/></xsl:attribute>
											<span style='font-size:82%;'><xsl:value-of select="./Prop[@Name='TS']/Prop[@Name='StepId']/Value"/></span>
										</td>
									</tr>
									-->
								</tbody>
							</table>
						</div>
						<xsl:apply-templates select="Prop[@Name='TS']/Prop[@Name='SequenceCall']">
							<xsl:with-param name="reportOptions" select="$reportOptions"/>
							<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
							<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
						</xsl:apply-templates>
						<xsl:apply-templates select="Prop[@Name='TS']/Prop[@Name='PostAction']">
							<xsl:with-param name="reportOptions" select="$reportOptions"/>
							<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
							<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
						</xsl:apply-templates>
					</div>
				</xsl:if>
				<xsl:if test="Prop[@Name='TS']/Prop[@Name='LoopIndex']">
					<xsl:value-of disable-output-escaping="yes" select="user:TestForEndLoopIndex()"/>
				</xsl:if>
			</xsl:for-each>
		</div>
	</xsl:template>
	<xsl:template match="Prop[@Name='PostAction']">
		<xsl:param name="reportOptions"/>
		<xsl:param name="labelBgColor"/>
		<xsl:param name="valueBgColor"/>
		<div>
			<!-- REMOVE_INDENTATION -->
			<xsl:value-of select="user:SetIndentationLevel(user:GetIndentationLevel() + 1)"/>
			<xsl:variable name="indentation" select="(user:GetIndentationLevel() + 1) * user:GetIndentationWidth() + 10"/>
			<br/>
			<h5>
				<xsl:value-of disable-output-escaping="yes" select="user:GetStepResultImage(.)"/>
				Begin Sequence: <xsl:value-of select="Prop[@Name='Sequence']/Value"/>
				<div style="padding:0px;margin-left:{$indentation}px;">
					<span style="white-space:nowrap;">
							(<xsl:apply-templates select="Prop[@Name='SequenceFile']"/>)
					</span>
				</div>
			</h5>
			<div class="StepResult">
				<xsl:attribute name="id"><xsl:value-of select="user:GetId(.,'s')"/></xsl:attribute>
				<xsl:attribute name="style"><xsl:value-of select="user:GetDIVStyle(.)"/></xsl:attribute>
				<!-- REMOVE_INDENTATION -->
				<xsl:value-of select="user:SetIndentationLevel(user:GetIndentationLevel() + 1)"/>
				<xsl:if test="Prop[@Name='ResultList']">
					<xsl:value-of disable-output-escaping="yes" select="user:SetResultLevel(user:GetResultLevel()+1)"/>
					<xsl:value-of select="user:StoreCurrentLoopingLevel()"/>
					<xsl:apply-templates select="Prop[@Name='ResultList']">
						<xsl:with-param name="reportOptions" select="$reportOptions"/>
						<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
						<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
					</xsl:apply-templates>
					<xsl:value-of select="user:ResetBlockLevel()"/>
					<xsl:value-of select="user:RestoreLoopingLevel()"/>
					<xsl:value-of disable-output-escaping="yes" select="user:SetResultLevel(user:GetResultLevel()-1)"/>
				</xsl:if>
				<xsl:if test="not (Prop[@Name='ResultList'])">
					<div>
						<!-- REMOVE_INDENTATION -->
						<xsl:value-of select="user:SetIndentationLevel(user:GetIndentationLevel() + 1)"/>
						<h5>
							<xsl:attribute name="style">margin-left:<xsl:value-of select="user:GetIndentationLevel() * user:GetIndentationWidth()"/>px;</xsl:attribute>No Sequence Results Found</h5>
						<!-- REMOVE_INDENTATION -->
						<xsl:value-of select="user:SetIndentationLevel(user:GetIndentationLevel() - 1)"/>
					</div>
				</xsl:if>
				<!-- REMOVE_INDENTATION -->
				<xsl:value-of select="user:SetIndentationLevel(user:GetIndentationLevel() - 1)"/>
				<h5>
					<xsl:attribute name="style">margin-left:<xsl:value-of select="user:GetIndentationLevel() * user:GetIndentationWidth()"/>px;</xsl:attribute>
					End Sequence: <xsl:value-of select="Prop[@Name='Sequence']/Value"/>
				</h5>
			</div>
			<!-- REMOVE_INDENTATION -->
			<xsl:value-of select="user:SetIndentationLevel(user:GetIndentationLevel() - 1)"/>
		</div>
	</xsl:template>
	<!-- XSLT Section 2.6 Template that adds the step name  and step execution status to the report table -->
	<xsl:template match="Prop[@Name='StepName']">
		<xsl:param name="colors"/>
		<tr>
			<td valign="top" colspan="2">
				<xsl:attribute name="style">border-color:<xsl:value-of select="$colors/Prop[@Name='TableBorder']/Value"/>;background-color:<xsl:call-template name="GetStepGroupBgColor">
						<xsl:with-param name="node" select="."/>
						<xsl:with-param name="colors" select="$colors"/>
					</xsl:call-template></xsl:attribute>
				<xsl:variable name="isCriticalFailure">
					<xsl:call-template name="GetIsCriticalFailure">
						<xsl:with-param name="node" select="."/>
					</xsl:call-template>
				</xsl:variable>
				<xsl:choose>
					<xsl:when test="$isCriticalFailure = 'True' ">
						<a>
							<xsl:attribute name="name">ResultId<xsl:value-of select="user:GetResultId(.)"/></xsl:attribute>
							<!-- Empty step name case -->
							<xsl:if test="Value=''">
								<xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text>
							</xsl:if>
							<xsl:value-of select="Value"/>
							<xsl:value-of select="user:GetLoopIndex(.)"/>
							<xsl:value-of select="user:GetStepNameAddition(.)"/>
						</a>
					</xsl:when>
					<xsl:otherwise>
						<!-- Empty step name case -->
						<xsl:if test="Value=''">
							<xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text>
						</xsl:if>
						<xsl:value-of select="Value"/>
						<xsl:value-of select="user:GetLoopIndex(.)"/>
						<xsl:value-of select="user:GetStepNameAddition(.)"/>
					</xsl:otherwise>
				</xsl:choose>
			</td>
		</tr>
	</xsl:template>
	<!-- Template that adds the Step execution status with the font color set -->
	<xsl:template match="Prop[@Name='Status']">
		<xsl:param name="colors"/>
		<tr>
			<td valign="top">
				<xsl:attribute name="style">border-color:<xsl:value-of select="$colors/Prop[@Name='TableBorder']/Value"/>;background-color:<xsl:value-of select="$colors/Prop[@Name = 'LabelBg']/Value" disable-output-escaping="no"/>;</xsl:attribute>
				<span style='font-size:82%;'>Status:</span>
			</td>
			<!-- ADD_IMG_STATUS Add images/colors into to step result row/column based on the step status	here-->
			<td valign="top">
				<xsl:attribute name="style">border-color:<xsl:value-of select="$colors/Prop[@Name='TableBorder']/Value"/>;background-color:<xsl:call-template name="GetStatusBgColor">
						<xsl:with-param name="colors" select="$colors"/>
						<xsl:with-param name="status" select="Value"/>
					</xsl:call-template>;width:<xsl:value-of select="$gSecondColumnWidth"/>%;</xsl:attribute>
				<span style='font-size:82%;'>
				<xsl:choose>
						<xsl:when test="string(Value) != ''">
							<xsl:value-of select="Value"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text>
						</xsl:otherwise>
					</xsl:choose>
				</span>
			</td>
		</tr>
	</xsl:template>
	<!-- XSLT Section 2.7 - None -->
	<!-- XSLT Section 2.8 Template that adds the Error Message and Report Text to the report -->
	<!-- Template that adds the Error Message to the report table-->
	<xsl:template match="Prop[@Name='Error']">
		<xsl:param name="reportOptions"/>
		<tr>
			<td valign="top" colspan="2">
				<xsl:attribute name="style">border-color:<xsl:value-of select="$reportOptions/Prop[@Name='Colors']/Prop[@Name='TableBorder']/Value"/>;background-color:<xsl:value-of select="$reportOptions/Prop[@Name = 'Colors']/Prop[@Name = 'ErrorBg']/Value" disable-output-escaping="no"/></xsl:attribute>
				<span style='font-size:82%;'>
					Error Message: 
					<xsl:value-of disable-output-escaping="yes" select="user:RemoveIllegalCharacters(Prop[@Name='Msg'])"/>
					[Error Code: <xsl:value-of select="Prop[@Name='Code']/Value"/>]
				</span>
			</td>
		</tr>
	</xsl:template>
	<!-- Template that adds the Report Text in the report -->
	<xsl:template match="Prop[@Name='ReportText']">
		<xsl:param name="reportTextBgColor"/>
		<tr>
			<td colspan="2">
				<xsl:attribute name="style">border-color:<xsl:value-of select="$reportTextBgColor/../../Prop[@Name='TableBorder']/Value"/>;background-color:<xsl:value-of select="$reportTextBgColor"/></xsl:attribute>
				<span style='font-size:82%;'>
					<xsl:value-of disable-output-escaping="yes" select="user:RemoveIllegalCharacters(.)"/>
				</span>
				<br/>
				<a>
					<xsl:attribute name="href"><xsl:value-of select="a/@HREF"/></xsl:attribute>
					<xsl:value-of select="a"/>
				</a>
			</td>
		</tr>
	</xsl:template>
	<!-- XSLT Section 2.9 Templates to add the interactive execution number to the report -->
	<xsl:template match="Prop[@Name='InteractiveExeNum']">
		<xsl:param name="labelBgColor"/>
		<xsl:param name="valueBgColor"/>
		<tr>
			<td valign="top">
				<xsl:attribute name="style">border-color:<xsl:value-of select="$labelBgColor/../../Prop[@Name='TableBorder']/Value"/>;background-color:<xsl:value-of select="$labelBgColor"/></xsl:attribute>
				<span style='font-size:82%;'>Interactive Execution #:</span>
			</td>
			<td valign="top">
				<xsl:attribute name="style">border-color:<xsl:value-of select="$valueBgColor/../../Prop[@Name='TableBorder']/Value"/>;background-color:<xsl:value-of select="$valueBgColor"/>;width:<xsl:value-of select="$gSecondColumnWidth"/>%;</xsl:attribute>
				<span style='font-size:82%;'>
					<xsl:value-of select="Value"/>
				</span>
			</td>
		</tr>
	</xsl:template>
	<!-- XSLT Section 2.10 Templates to add Server information to the report -->
	<xsl:template match="Prop[@Name='Server']">
		<xsl:param name="labelBgColor"/>
		<xsl:param name="valueBgColor"/>
		<tr>
			<td valign="top">
				<xsl:attribute name="style">border-color:<xsl:value-of select="$labelBgColor/../../Prop[@Name='TableBorder']/Value"/>;background-color:<xsl:value-of select="$labelBgColor"/></xsl:attribute>
				<span style='font-size:82%;'>Server:</span>
			</td>
			<td valign="top">
				<xsl:attribute name="style">border-color:<xsl:value-of select="$valueBgColor/../../Prop[@Name='TableBorder']/Value"/>;background-color:<xsl:value-of select="$valueBgColor"/>;width:<xsl:value-of select="$gSecondColumnWidth"/>%;</xsl:attribute>
				<span style='font-size:82%;'>
					<xsl:value-of select="Value"/>
				</span>
			</td>
		</tr>
	</xsl:template>
	<!-- XSLT Section 2.11 Templates to handle summary information for the loops of particular step in case 'looping' is enabled for the step or the user loops or runs some selected steps only-->
	<xsl:template match="Prop[@Name='NumLoops']">
		<xsl:param name="labelBgColor"/>
		<xsl:param name="valueBgColor"/>
		<tr>
			<td valign="top">
				<xsl:attribute name="style">border-color:<xsl:value-of select="$labelBgColor/../../Prop[@Name='TableBorder']/Value"/>;background-color:<xsl:value-of select="$labelBgColor"/></xsl:attribute>
				<span style='font-size:82%;'>Number of Loops:</span>
			</td>
			<td valign="top">
				<xsl:attribute name="style">border-color:<xsl:value-of select="$valueBgColor/../../Prop[@Name='TableBorder']/Value"/>;background-color:<xsl:value-of select="$valueBgColor"/>;width:<xsl:value-of select="$gSecondColumnWidth"/>%</xsl:attribute>
				<span style='font-size:82%;'>
					<xsl:value-of select="Value"/>
				</span>
			</td>
		</tr>
	</xsl:template>
	<xsl:template match="Prop[@Name='NumPassed']">
		<xsl:param name="labelBgColor"/>
		<xsl:param name="valueBgColor"/>
		<tr>
			<td valign="top">
				<xsl:attribute name="style">border-color:<xsl:value-of select="$labelBgColor/../../Prop[@Name='TableBorder']/Value"/>;background-color:<xsl:value-of select="$labelBgColor"/></xsl:attribute>
				<span style='font-size:82%;'>Number of Passes:</span>
			</td>
			<td valign="top">
				<xsl:attribute name="style">border-color:<xsl:value-of select="$labelBgColor/../../Prop[@Name='TableBorder']/Value"/>;background-color:<xsl:value-of select="$valueBgColor"/>;width:<xsl:value-of select="$gSecondColumnWidth"/>%</xsl:attribute>
				<span style='font-size:82%;'>
					<xsl:value-of select="Value"/>
				</span>
			</td>
		</tr>
	</xsl:template>
	<xsl:template match="Prop[@Name='NumFailed']">
		<xsl:param name="labelBgColor"/>
		<xsl:param name="valueBgColor"/>
		<tr>
			<td valign="top">
				<xsl:attribute name="style">border-color:<xsl:value-of select="$labelBgColor/../../Prop[@Name='TableBorder']/Value"/>;background-color:<xsl:value-of select="$labelBgColor"/></xsl:attribute>
				<span style='font-size:82%;'>Number of Failures:</span>
			</td>
			<td valign="top">
				<xsl:attribute name="style">border-color:<xsl:value-of select="$labelBgColor/../../Prop[@Name='TableBorder']/Value"/>;background-color:<xsl:value-of select="$valueBgColor"/>;width:<xsl:value-of select="$gSecondColumnWidth"/>%</xsl:attribute>
				<span style='font-size:82%;'>
					<xsl:value-of select="Value"/>
				</span>
			</td>
		</tr>
	</xsl:template>
	<xsl:template match="Prop[@Name='EndingLoopIndex']">
		<xsl:param name="labelBgColor"/>
		<xsl:param name="valueBgColor"/>
		<xsl:param name="useLocalizedDecimalPoint"/>
		<tr>
			<td valign="top">
				<xsl:attribute name="style">border-color:<xsl:value-of select="$labelBgColor/../../Prop[@Name='TableBorder']/Value"/>;background-color:<xsl:value-of select="$labelBgColor"/></xsl:attribute>
				<span style='font-size:82%;'>Final Loop Index:</span>
			</td>
			<td valign="top">
				<xsl:attribute name="style">border-color:<xsl:value-of select="$labelBgColor/../../Prop[@Name='TableBorder']/Value"/>;background-color:<xsl:value-of select="$valueBgColor"/>;width:<xsl:value-of select="$gSecondColumnWidth"/>%</xsl:attribute>
				<span style='font-size:82%;'>
					<xsl:choose>
						<xsl:when test="$useLocalizedDecimalPoint = 'True' and $gLocalizedDecimalPoint != '.'">
							<xsl:value-of select="translate(Value, '.', $gLocalizedDecimalPoint)"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="Value"/>
						</xsl:otherwise>
					</xsl:choose>
				</span>
			</td>
		</tr>
	</xsl:template>
	<!-- XSLT Section 2.12 Templates to create the critical failure stack table for a failed test-->
	<xsl:template match="Prop[@Name='CriticalFailureStack']">
		<xsl:param name="tableBorderColor"/>
		<xsl:param name="failureStackLabelBgColor"/>
		<xsl:param name="failureStackValueBgColor"/>
		<xsl:if test="Value">
			<table>
				<xsl:attribute name="style">width:70%;border-width:1px;border-style:solid;border-color:<xsl:value-of select="$tableBorderColor"/>
				</xsl:attribute>
				<tbody>
					<tr>
						<td>
							<xsl:attribute name="style">border-color:<xsl:value-of select="$tableBorderColor"/>;background-color:<xsl:value-of select="$failureStackLabelBgColor"/></xsl:attribute>
							<b>Step</b>
						</td>
						<td>
							<xsl:attribute name="style">border-color:<xsl:value-of select="$tableBorderColor"/>;background-color:<xsl:value-of select="$failureStackLabelBgColor"/></xsl:attribute>
							<b>Sequence</b>
						</td>
						<td>
							<xsl:attribute name="style">border-color:<xsl:value-of select="$tableBorderColor"/>;background-color:<xsl:value-of select="$failureStackLabelBgColor"/></xsl:attribute>
							<b>Sequence File</b>
						</td>
					</tr>
					<xsl:for-each select="Value">
						<xsl:sort select="@ID" order="descending"/>
						<tr>
							<td>
								<xsl:attribute name="style">border-color:<xsl:value-of select="$tableBorderColor"/>;background-color:<xsl:value-of select="$failureStackValueBgColor"/></xsl:attribute>
								<a>
									<xsl:attribute name="href">#ResultId<xsl:value-of select="Prop/Prop[@Name='ResultId']/Value"/></xsl:attribute>
									<xsl:attribute name="onclick">ExpandTable()</xsl:attribute>
									<xsl:value-of select="Prop/Prop[@Name='StepName']/Value"/>
								</a>
							</td>
							<td>
								<xsl:attribute name="style">border-color:<xsl:value-of select="$tableBorderColor"/>;background-color:<xsl:value-of select="$failureStackValueBgColor"/></xsl:attribute>
								<xsl:value-of select="Prop/Prop[@Name='SequenceName']/Value"/>
							</td>
							<td>
								<xsl:attribute name="style">border-color:<xsl:value-of select="$tableBorderColor"/>;background-color:<xsl:value-of select="$failureStackValueBgColor"/></xsl:attribute>
								<xsl:choose>
									<xsl:when test="Prop/Prop[@Name='SequenceFileName']/Value != ''">
										<xsl:value-of select="Prop/Prop[@Name='SequenceFileName']/Value"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of disable-output-escaping="yes" select="$gUnsavedSeqFileName"/>
									</xsl:otherwise>
								</xsl:choose>
							</td>
						</tr>
					</xsl:for-each>
				</tbody>
			</table>
			<br/>
		</xsl:if>
	</xsl:template>
	<!-- XSLT Section 2.13: Templates to add module time to the report -->
	<xsl:template match="Prop[@Name='ModuleTime']">
		<xsl:value-of disable-output-escaping="yes" select="user:GetModuleTime(Value)"/>
	</xsl:template>
	<!-- XSLT Section 3  Templates to process Batch report	-->
	<!-- XSLT Section 3.1 Template to process the batch header table and call the template to build the batch report table-->
	<xsl:template match="Report[@Type='Batch']">
		<xsl:value-of select="user:InitFlagGlobalVariables(Prop[@Name='ReportOptions'])"/>
		<xsl:value-of select="user:InitColorGlobalVariables(Prop[@Name='ReportOptions']/Prop[@Name='Colors'])"/>
		<xsl:variable name="reportOptions" select="Prop[@Name='ReportOptions']"/>
		<h3>
			<xsl:value-of select="@Title"/>
		</h3>
		<table style="width:70%;" frame="void">
			<tbody>
				<xsl:apply-templates select="Prop[@Name='StationInfo']/Prop[@Name='StationID']"/>
				<tr>
					<td class="ReportHeader" style="white-space:nowrap">
						<b>
							 Serial Number: 
						</b>
					</td>
					<td class="ReportHeader">
						<b>
							<xsl:value-of select="user:GetSerialNumber(@BatchSerialNumber)"/>
						</b>
					</td>
				</tr>
				<xsl:apply-templates select="Prop[@Name='StartDate']"/>
				<xsl:apply-templates select="Prop[@Name='StartTime']"/>
				<xsl:apply-templates select="Prop[@Name='StationInfo']/Prop[@Name='LoginName']"/>
				<xsl:apply-templates select="Prop[@Name='TSRData']/Prop[@Name='TSRFileName']"/>
				<xsl:apply-templates select="Prop[@Name='TSRData']/Prop[@Name='TSRFileID']"/>
				<xsl:apply-templates select="Prop[@Name='TSRData']/Prop[@Name='TSRFileClosed']"/>
			</tbody>
		</table>
		<br/>
		<xsl:apply-templates select="BatchTable">
			<xsl:with-param name="reportOptions" select="$reportOptions"/>
		</xsl:apply-templates>
		<h3>End Batch Report</h3>
		<hr>
			<xsl:attribute name="style">border-width:0;width:90%;height:5px;color:<xsl:value-of select="$reportOptions/Prop[@Name = 'Colors']/Prop[@Name = 'UUTSeparator']/Value" disable-output-escaping="no"/>;background-color:<xsl:value-of select="$reportOptions/Prop[@Name = 'Colors']/Prop[@Name = 'UUTSeparator']/Value" disable-output-escaping="no"/></xsl:attribute>
		</hr>
	</xsl:template>
	<!-- XSLT Section 3.2 Template to build the Batch report table-->
	<xsl:template match="BatchTable">
		<xsl:param name="reportOptions"/>
		<table>
			<xsl:attribute name="style">width:70%;border-width:1px;border-style:solid;border-color:<xsl:value-of select="$reportOptions/Prop[@Name = 'Colors']/Prop[@Name = 'TableBorder']/Value" disable-output-escaping="no"/></xsl:attribute>
			<tr style="text-align:center;background-color:{$reportOptions/Prop[@Name = 'Colors']/Prop[@Name = 'BatchHeadingBg']/Value};">
				<td>
					<xsl:attribute name="style">width:20%;border-color:<xsl:value-of select="$reportOptions/Prop[@Name = 'Colors']/Prop[@Name = 'TableBorder']/Value" disable-output-escaping="no"/></xsl:attribute>
					<b>Test Socket</b>
				</td>
				<td>
					<xsl:attribute name="style">width:60%;border-color:<xsl:value-of select="$reportOptions/Prop[@Name = 'Colors']/Prop[@Name = 'TableBorder']/Value" disable-output-escaping="no"/></xsl:attribute>
					<b>UUT Serial Number</b>
				</td>
				<td>
					<xsl:attribute name="style">width:20%;border-color:<xsl:value-of select="$reportOptions/Prop[@Name = 'Colors']/Prop[@Name = 'TableBorder']/Value" disable-output-escaping="no"/></xsl:attribute>
					<b>UUT Result</b>
				</td>
			</tr>
			<xsl:apply-templates select="UUThref">
				<xsl:with-param name="reportOptions" select="$reportOptions"/>
			</xsl:apply-templates>
		</table>
	</xsl:template>
	<!-- XSLT Section 3.3 Template to add data into the Batch report table.-->
	<xsl:template match="UUThref">
		<xsl:param name="reportOptions"/>
		<tr style="text-align:center;">
			<td>
				<xsl:attribute name="style">border-color:<xsl:value-of select="$reportOptions/Prop[@Name = 'Colors']/Prop[@Name = 'TableBorder']/Value" disable-output-escaping="no"/></xsl:attribute>
				<xsl:choose>
						<xsl:when test="string(@SocketIndex) != ''">
							<xsl:value-of select="@SocketIndex"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text>
						</xsl:otherwise>
					</xsl:choose>
			</td>
			<td>
				<xsl:attribute name="style">border-color:<xsl:value-of select="$reportOptions/Prop[@Name = 'Colors']/Prop[@Name = 'TableBorder']/Value" disable-output-escaping="no"/></xsl:attribute>
				<xsl:value-of select="user:GetLinkURL(.)" disable-output-escaping="yes"/>
			</td>
			<td>
				<xsl:attribute name="style">border-color:<xsl:value-of select="$reportOptions/Prop[@Name = 'Colors']/Prop[@Name = 'TableBorder']/Value" disable-output-escaping="no"/>;background-color:<xsl:call-template name="GetStatusBgColor">
						<xsl:with-param name="colors" select="$reportOptions/Prop[@Name = 'Colors']"/>
						<xsl:with-param name="status" select="@UUTResult"/>	
					</xsl:call-template></xsl:attribute>
					<xsl:choose>
						<xsl:when test="string(@UUTResult) != ''">
							<xsl:value-of select="@UUTResult"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text>
						</xsl:otherwise>
					</xsl:choose>
			</td>
		</tr>
	</xsl:template>
	<!-- XSLT Section 4  Templates common to both UUT and Batch report	-->
	<!-- XSLT Section 4.1  Template to get the stationID and Login Name -->
	<!-- Template to add the StationID to the report-->
	<xsl:template match="Prop[@Name='StationID']">
		<tr>
			<td class="ReportHeader" style="white-space:nowrap">
				<b>
					 Station ID: 
				</b>
			</td>
			<td class="ReportHeader">
				<b>
					<xsl:value-of select="Value"/>
				</b>
			</td>
		</tr>
	</xsl:template>
	<!-- Template to add Login Name to the report -->
	<xsl:template match="Prop[@Name='LoginName']">
		<tr>
			<td class="ReportHeader" style="white-space:nowrap">
				<b>
					 Operator: 
				</b>
			</td>
			<td class="ReportHeader">
				<b>
					<xsl:value-of select="Value"/>
				</b>
			</td>
		</tr>
	</xsl:template>
	<!-- XSLT Section 4.2  Template to get the Start Date and Start Time of the report-->
	<!-- Template to add Start Date to the report-->
	<xsl:template match="Prop[@Name='StartDate']">
		<tr>
			<td class="ReportHeader" style="white-space:nowrap">
				<b>
					 Date: 
				</b>
			</td>
			<td class="ReportHeader">
				<b>
					<xsl:value-of select="Prop[@Name='Text']/Value"/>
				</b>
			</td>
		</tr>
	</xsl:template>
	<!-- Template to add Start Time of the report -->
	<xsl:template match="Prop[@Name='StartTime']">
		<tr>
			<td class="ReportHeader" style="white-space:nowrap">
				<b>
					 Time: 
				</b>
			</td>
			<td class="ReportHeader">
				<b>
					<xsl:value-of select="Prop[@Name='Text']/Value"/>
				</b>
			</td>
		</tr>
	</xsl:template>
	<!--XSLT Section 5 Templates to insert all flagged information into the report table along with addtional results.-->
	<!-- XSLT Section 5.1 - None -->
	<!-- XSLT Section 5.2 Template to return the status color as configured in the report options.-->
	<xsl:template name="GetStatusColor">
		<xsl:param name="colors"/>
		<xsl:param name="status"/>
		<xsl:choose>
			<xsl:when test="$status = 'Passed'">
				<xsl:value-of select="$colors/Prop[@Name = 'Passed']/Value" disable-output-escaping="no"/>
			</xsl:when>
			<xsl:when test="$status = 'Done'">
				<xsl:value-of select="$colors/Prop[@Name = 'Done']/Value" disable-output-escaping="no"/>
			</xsl:when>
			<xsl:when test="$status = 'Failed'">
				<xsl:value-of select="$colors/Prop[@Name = 'Failed']/Value" disable-output-escaping="no"/>
			</xsl:when>
			<xsl:when test="$status = 'Error'">
				<xsl:value-of select="$colors/Prop[@Name = 'Error']/Value" disable-output-escaping="no"/>
			</xsl:when>
			<xsl:when test="$status = 'Terminated'">
				<xsl:value-of select="$colors/Prop[@Name = 'Terminated']/Value" disable-output-escaping="no"/>
			</xsl:when>
			<xsl:when test="$status = 'Running'">
				<xsl:value-of select="$colors/Prop[@Name = 'Running']/Value" disable-output-escaping="no"/>
			</xsl:when>
			<xsl:otherwise>
						<xsl:value-of select="$colors/Prop[@Name = 'Skipped']/Value" disable-output-escaping="no"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- XSLT Section 5.3 Template to return the status background color as configured in the report options.-->
	<xsl:template name="GetStatusBgColor">
		<xsl:param name="colors"/>
		<xsl:param name="status"/>
		<xsl:choose>
			<xsl:when test="$status = 'Passed'">
				<xsl:value-of select="$colors/Prop[@Name = 'PassedBg']/Value" disable-output-escaping="no"/>
			</xsl:when>
			<xsl:when test="$status = 'Done'">
				<xsl:value-of select="$colors/Prop[@Name = 'DoneBg']/Value" disable-output-escaping="no"/>
			</xsl:when>
			<xsl:when test="$status = 'Failed'">
				<xsl:value-of select="$colors/Prop[@Name = 'FailedBg']/Value" disable-output-escaping="no"/>
			</xsl:when>
			<xsl:when test="$status = 'Error'">
				<xsl:value-of select="$colors/Prop[@Name = 'ErrorBg']/Value" disable-output-escaping="no"/>
			</xsl:when>
			<xsl:when test="$status = 'Terminated'">
				<xsl:value-of select="$colors/Prop[@Name = 'TerminatedBg']/Value" disable-output-escaping="no"/>
			</xsl:when>
			<xsl:when test="$status = 'Running'">
				<xsl:value-of select="$colors/Prop[@Name = 'RunningBg']/Value" disable-output-escaping="no"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$colors/Prop[@Name = 'SkippedBg']/Value" disable-output-escaping="no"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- XSLT Section 5.4 Template to put flagged values in report.-->
	<xsl:template name="PutFlaggedValuesInReport">
		<xsl:param name="propNodes"/>
		<xsl:param name="parentPropName"/>
		<xsl:param name="bAddPropertyToReport"/>
		<xsl:param name="nLevel"/>
		<xsl:param name="reportOptions"/>
		<xsl:param name="labelBgColor"/>
		<xsl:param name="valueBgColor"/>
		<xsl:param name="flattenedStructure" select="false()"/>
		<xsl:param name="objectPath"/>
		<xsl:for-each select="$propNodes">
			<xsl:variable name="propLabel">
				<xsl:choose>
					<xsl:when test="@Name">
						<xsl:choose>
							<xsl:when test="@Name != '' "><xsl:value-of select="@Name"/></xsl:when>
							<xsl:otherwise><xsl:value-of select="$parentPropName"/></xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$parentPropName"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:variable name="currentNode" select="."/>
			<xsl:call-template name="AddIfFlagSet">
				<xsl:with-param name="propNode" select="$currentNode"/>
				<xsl:with-param name="propLabel" select="$propLabel"/>
				<xsl:with-param name="bAddPropertyToReport" select="$bAddPropertyToReport"/>
				<xsl:with-param name="nLevel" select="$nLevel"/>
				<xsl:with-param name="reportOptions" select="$reportOptions"/>
				<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
				<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
				<xsl:with-param name="flattenedStructure" select="$flattenedStructure"/>
				<xsl:with-param name="objectPath" select="$objectPath"/>
			</xsl:call-template>
		</xsl:for-each>
	</xsl:template>
	<!-- XSLT Section 5.5 Template to add values into report if the flag to include it in the report is set.-->
	<xsl:template name="AddIfFlagSet">
		<xsl:param name="propNode"/>
		<xsl:param name="propLabel"/>
		<xsl:param name="bAddPropertyToReport"/>
		<xsl:param name="nLevel"/>
		<xsl:param name="reportOptions"/>
		<xsl:param name="labelBgColor"/>
		<xsl:param name="valueBgColor"/>
		<xsl:param name="flattenedStructure" select="false()"/>
		<xsl:param name="objectPath"/>
		<xsl:variable name="currentObjPath">
			<xsl:choose>
				<xsl:when test="$objectPath = ''">
					<xsl:if test="@Name != 'AdditionalData' or parent::node()/@Name!='UUT' or $nLevel!=0">
						<xsl:value-of select="@Name"/>
					</xsl:if>
				</xsl:when>
				<xsl:otherwise>
					<xsl:choose>
						<xsl:when test="@Name and @Name != ''">
							<xsl:value-of select="concat($objectPath, '.', @Name)"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="$objectPath"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="gIncludeMeasurement" select="$reportOptions/Prop[@Name = 'IncludeMeasurements']/Value"/>
		<xsl:variable name="gIncludeLimits" select="$reportOptions/Prop[@Name = 'IncludeLimits']/Value"/>
		<xsl:variable name="gIncludeAttributes" select="$reportOptions/Prop[@Name = 'IncludeAttributes']/Value"/>
		<xsl:variable name="parentPropType" select="$propNode/../@Type"/>
		<xsl:choose>
			<!--The stylesheet will not process the properties under the TS and Error element directly under the TEResult element. These properties will be handled by specific templates -->
			<xsl:when test="($propNode/@Name = 'TS' or $propNode/@Name = 'Error') and $parentPropType = 'TEResult' "/>
			<xsl:otherwise>
				<xsl:choose>
					<!-- Check if the property needs to be added to the Report-->
					<!--Convert the gIncludeMeasurement and gIncludeLimits variables to string so that they can be compared against True/False values
					in Javascript-->
					<xsl:when test="user:AddPropertyToReport(., $bAddPropertyToReport, string($gIncludeMeasurement), string($gIncludeLimits))">
						<xsl:choose>
							<xsl:when test="./@Type = 'Array'">
								<xsl:variable name="numDimensions">
									<xsl:call-template name="GetArrayDimensions">
										<xsl:with-param name="dimensionString" select="@LBound"/>
									</xsl:call-template>
								</xsl:variable>
								<xsl:variable name="propNodeRepresentation">
									<xsl:choose>
										<xsl:when test="$propNode/@Representation">
											<xsl:value-of select="$propNode/@Representation"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:text>DBL</xsl:text>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								<xsl:variable name="isDecimal">
									<xsl:choose>
										<xsl:when test="$propNode/@NumFmt">
											<xsl:value-of select="user:IsOfDecimalFormat(string($propNode/@NumFmt))"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="user:IsOfDecimalFormat(string($reportOptions/Prop[@Name='NumericFormat']/Value/text()))"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								<xsl:variable name="includeArrayMeasurement" select="user:ConvertToDecimalValue(string($reportOptions/Prop[@Name = 'IncludeArrayMeasurement']/Value))"/>
								<xsl:choose>
									<!-- Call AddArrayToReportAsGraph only if the array elements are numeric type and the number of dimensions is less than or equal to 2 and IncludeArrayMeasurement report option is set to Insert Graph and the graph control is installed
										and if representation is not UInt64 and I64-->
									<xsl:when test="($numDimensions - 1) &lt;= 2 and @ElementType = 'Number' and $includeArrayMeasurement = 2 and $propNodeRepresentation = 'DBL' and $isDecimal = 'true' and count(./Value)>0">
									<xsl:variable name="arrayTable">
										<xsl:choose>
											<xsl:when test="$gGraphControlInstalled != 1">
												<xsl:call-template name="AddArrayToReportAsTable">
														<xsl:with-param name="propNode" select="$propNode"/>
														<xsl:with-param name="propName" select="@Name"/>
														<xsl:with-param name="propLabel" select="$propLabel"/>
														<xsl:with-param name="nLevel" select="$nLevel"/>
														<xsl:with-param name="reportOptions" select="$reportOptions"/>
														<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
														<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
														<xsl:with-param name="flattenedStructure" select="$flattenedStructure"/>
														<xsl:with-param name="objectPath" select="$currentObjPath"/>
														<xsl:with-param name="bAddLabelAndAttributes" select="false()"/>
													</xsl:call-template>
												</xsl:when>
												<xsl:otherwise><xsl:value-of select="''"/></xsl:otherwise>
										</xsl:choose>
									</xsl:variable>
									<xsl:value-of select="user:AddArrayToReportAsGraph($propNode, @Name, string($propLabel), $nLevel, boolean($flattenedStructure), string($currentObjPath), string($arrayTable))" disable-output-escaping="yes"/>
									<xsl:if test="$gIncludeAttributes='True'">
										<xsl:call-template name="AddAttributesToReport">
											<xsl:with-param name="reportOptions" select="$reportOptions"/>
											<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
											<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
											<xsl:with-param name="nLevel" select="$nLevel"/>
											<xsl:with-param name="flattenedStructure" select="$flattenedStructure"/>
											<xsl:with-param name="objectPath" select="$currentObjPath"/>
										</xsl:call-template>
									</xsl:if>
									</xsl:when>
									<xsl:otherwise>
										<!-- For all other cases the array will be added as a table -->
										   <xsl:call-template name="AddArrayToReportAsTable">
												<xsl:with-param name="propNode" select="$propNode"/>
												<xsl:with-param name="propName" select="@Name"/>
												<xsl:with-param name="propLabel" select="$propLabel"/>
												<xsl:with-param name="nLevel" select="$nLevel"/>
												<xsl:with-param name="reportOptions" select="$reportOptions"/>
												<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
												<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
												<xsl:with-param name="flattenedStructure" select="$flattenedStructure"/>
												<xsl:with-param name="objectPath" select="$currentObjPath"/>
											</xsl:call-template>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:when>
							<xsl:otherwise>
								<xsl:choose>
									<xsl:when test="./Value">
										<!-- In case the property is a leaf node add it as line to the report. Localize the decimal point if it is a number and the report option UseLocalizedDecimalPoint is set to true.-->
										<xsl:call-template name="GetResultLine">
											<xsl:with-param name="name" select="./@Name"/>
											<xsl:with-param name="value" select="./Value"/>
											<xsl:with-param name="parentNode" select="$propLabel"/>
											<xsl:with-param name="nLevel" select="$nLevel"/>
											<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
											<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
											<xsl:with-param name="propNode" select="."/>
											<xsl:with-param name="flattenedStructure" select="$flattenedStructure"/>
											<xsl:with-param name="objectPath" select="$currentObjPath"/>
											<xsl:with-param name="reportOptions" select="$reportOptions"/>
										</xsl:call-template>
										<xsl:if test="$gIncludeAttributes='True'">
											<xsl:call-template name="AddAttributesToReport">
												<xsl:with-param name="reportOptions" select="$reportOptions"/>
												<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
												<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
												<xsl:with-param name="nLevel" select="$nLevel"/>
												<xsl:with-param name="flattenedStructure" select="$flattenedStructure"/>
												<xsl:with-param name="objectPath" select="$currentObjPath"/>
											</xsl:call-template>
										</xsl:if>
									</xsl:when>
									<xsl:otherwise>
										<!--in case the property is a container with at least 1 child property with the Flags attribute add the property and call PutFlaggedValuesInReport passing the child elements-->
										<xsl:if test="count(./Prop[@Flags]) &gt; 0">
											<xsl:choose>
												<xsl:when test="./@TypeName = 'NI_TDMSReference'">
													<xsl:call-template name="PutTDMSReference">
														<xsl:with-param name="propNodes" select="./Prop[@Flags]"/>
														<xsl:with-param name="bAddPropertyToReport" select="1"/>
														<xsl:with-param name="nLevel" select="$nLevel"/>
														<xsl:with-param name="reportOptions" select="$reportOptions"/>
														<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
														<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
														<xsl:with-param name="propLabel" select="$propLabel"/>
														<xsl:with-param name="flattenedStructure" select="$flattenedStructure"/>
														<xsl:with-param name="objectPath" select="$currentObjPath"/>
													</xsl:call-template>
												</xsl:when>
												<xsl:otherwise>
													<xsl:if test="$flattenedStructure = false()">
														<tr>
															<td valign="top" colspan='2'>
																<xsl:attribute name="style">border-color:<xsl:value-of select="$reportOptions/Prop[@Name='Colors']/Prop[@Name='TableBorder']/Value"/>;background-color:<xsl:value-of select="$labelBgColor"/>;width:<xsl:value-of select="$gSecondColumnWidth"/>%;</xsl:attribute>
																<span style='font-size:82%;color:{$labelBgColor};'>
																	<xsl:call-template name="GetIndentationString">
																		<xsl:with-param name="nLevel" select="$nLevel"/>
																	</xsl:call-template>
																</span>
																<span style='font-size:82%;'>
																	<xsl:value-of select="$propLabel"/>:</span>
															</td>
														</tr>
													</xsl:if>
													<xsl:if test="$gIncludeAttributes='True' and ./Attributes">
														<xsl:call-template name="AddAttributesToReport">
															<xsl:with-param name="reportOptions" select="$reportOptions"/>
															<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
															<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
															<xsl:with-param name="nLevel" select="$nLevel"/>
															<xsl:with-param name="flattenedStructure" select="$flattenedStructure"/>
															<xsl:with-param name="objectPath" select="$currentObjPath"/>
														</xsl:call-template>
													</xsl:if>
													<xsl:call-template name="PutFlaggedValuesInReport">
														<xsl:with-param name="propNodes" select="./Prop[@Flags]"/>
														<xsl:with-param name="parentPropName" select="./@Name"/>
														<xsl:with-param name="bAddPropertyToReport" select="1"/>
														<xsl:with-param name="nLevel" select="$nLevel +1"/>
														<xsl:with-param name="reportOptions" select="$reportOptions"/>
														<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
														<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
														<xsl:with-param name="flattenedStructure" select="$flattenedStructure"/>
														<xsl:with-param name="objectPath" select="$currentObjPath"/>
													</xsl:call-template>
												</xsl:otherwise>
											</xsl:choose>
										</xsl:if>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<xsl:otherwise>
						<xsl:choose>
							<xsl:when test="./@Type = 'Array'">
								<!-- For arrays of Objects, call PutFlaggedValuesInReport for each of the child properties-->
								<xsl:if test="$propNode/@ElementType = 'Obj'">
									<xsl:variable name="addLabel" select="$gIncludeAttributes='True' and $flattenedStructure=false() and ($nLevel != 0 or ($propNode/@Name!='AdditionalResults' and $propNode/@Name!='Parameters' )) and user:CheckIfIncludeInReportIsPresentForAttributes($propNode//Prop[@Flags and @Type], $reportOptions)"/>
										<xsl:if test="$addLabel">
											<tr>
												<td valign="top" colspan='2'>
													<xsl:attribute name="style">border-color:<xsl:value-of select="$reportOptions/Prop[@Name = 'Colors']/Prop[@Name = 'TableBorder']/Value"/>;width:<xsl:value-of select="$gSecondColumnWidth"/>%;background-color:<xsl:value-of select="$labelBgColor"/></xsl:attribute>
													<span style='font-size:82%;color:{$labelBgColor};'>
														<xsl:call-template name="GetIndentationString">
															<xsl:with-param name="nLevel" select="$nLevel"/>
														</xsl:call-template>
													</span>
													<span style='font-size:82%;'>
														<xsl:value-of select="$propLabel"/>:
													</span>
												</td>
											</tr>
										</xsl:if>
									<xsl:variable name="valueNodes" select="$propNode/Value"/>
									<xsl:variable name="nextLevel">
										<xsl:choose>
											<xsl:when test="$addLabel"><xsl:value-of select="$nLevel + 1"/></xsl:when>
											<xsl:otherwise><xsl:value-of select="$nLevel"/></xsl:otherwise>
										</xsl:choose>
									</xsl:variable>
									<xsl:for-each select="$valueNodes">
										<xsl:if test="count(./Prop[@Flags]) &gt; 0">
											<xsl:call-template name="PutFlaggedValuesInReport">
												<xsl:with-param name="propNodes" select="./Prop[@Flags]"/>
												<xsl:with-param name="parentPropName" select="concat($propLabel,@ID)"/>
												<xsl:with-param name="bAddPropertyToReport" select="0"/>
												<xsl:with-param name="nLevel" select="number($nextLevel)"/>
												<xsl:with-param name="reportOptions" select="$reportOptions"/>
												<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
												<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
												<xsl:with-param name="flattenedStructure" select="$flattenedStructure"/>
												<xsl:with-param name="objectPath" select="$currentObjPath"/>
											</xsl:call-template>
										</xsl:if>
									</xsl:for-each>
								</xsl:if>
							</xsl:when>
							<xsl:otherwise>
								<xsl:if test="count($propNode/Prop[@Flags and @Type]) &gt; 0">
									<xsl:if test="$flattenedStructure=false() and $gIncludeAttributes='True' and user:CheckIfIncludeInReportIsPresentForAttributes($propNode//Prop[@Flags and @Type], $reportOptions)">
										<tr>
											<td valign="top" colspan='2'>
												<xsl:attribute name="style">border-color:<xsl:value-of select="$reportOptions/Prop[@Name='Colors']/Prop[@Name='TableBorder']/Value"/>;background-color:<xsl:value-of select="$labelBgColor"/>;width:<xsl:value-of select="$gSecondColumnWidth"/>%;</xsl:attribute>
												<span style='font-size:82%;color:{$labelBgColor};'>
													<xsl:call-template name="GetIndentationString">
														<xsl:with-param name="nLevel" select="$nLevel"/>
													</xsl:call-template>
												</span>
												<span style='font-size:82%;'>
													<xsl:value-of select="$propLabel"/>:
												</span>
											</td>
										</tr>
									</xsl:if>
									<xsl:call-template name="PutFlaggedValuesInReport">
										<xsl:with-param name="propNodes" select="$propNode/Prop[@Flags]"/>
										<xsl:with-param name="parentPropName" select="./@Name"/>
										<xsl:with-param name="bAddPropertyToReport" select="0"/>
										<xsl:with-param name="nLevel" select="$nLevel+1"/>
										<xsl:with-param name="reportOptions" select="$reportOptions"/>
										<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
										<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
										<xsl:with-param name="flattenedStructure" select="$flattenedStructure"/>
										<xsl:with-param name="objectPath" select="$currentObjPath"/>
									</xsl:call-template>
								</xsl:if>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!--Template to add attributes, if present, for the flagged values put in the report.-->
	<xsl:template name="AddAttributesToReport">
		<xsl:param name="reportOptions"/>
		<xsl:param name="labelBgColor"/>
		<xsl:param name="valueBgColor"/>
		<xsl:param name="nLevel"/>
		<xsl:param name="flattenedStructure" select="false()"/>
		<xsl:param name="objectPath"/>
		<xsl:if test="./Attributes">
			<xsl:variable name="attributePropNodes" select="./Attributes//Prop[@Flags and @Type]"/>
			<xsl:if test="user:CheckIfIncludeInReportIsPresentForAttributes($attributePropNodes, $reportOptions)">
				<xsl:if test="$flattenedStructure = false()">
					<tr>
						<td valign="top" colspan='2'>
							<xsl:attribute name="style">border-color:<xsl:value-of select="$reportOptions/Prop[@Name='Colors']/Prop[@Name='TableBorder']/Value"/>;background-color:<xsl:value-of select="$labelBgColor"/>;width:<xsl:value-of select="$gSecondColumnWidth"/>%;</xsl:attribute>
							<span style='font-size:82%;color:{$labelBgColor};'>
								<xsl:call-template name="GetIndentationString">
									<xsl:with-param name="nLevel" select="$nLevel + 1"/>
								</xsl:call-template>
							</span>
							<span style='font-size:82%;'>
								Attributes:
							</span>
						</td>
					</tr>
				</xsl:if>
				<xsl:call-template name="PutFlaggedValuesInReport">
					<xsl:with-param name="propNodes" select="./Attributes/Prop[@Flags]"/>
					<xsl:with-param name="parentPropName" select="Attributes"/>
					<xsl:with-param name="bAddPropertyToReport" select="0"/>
					<xsl:with-param name="nLevel" select="$nLevel + 2"/>
					<xsl:with-param name="reportOptions" select="$reportOptions"/>
					<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
					<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
					<xsl:with-param name="flattenedStructure" select="$flattenedStructure"/>
					<xsl:with-param name="objectPath" select="concat($objectPath, '.Attributes')"/>
				</xsl:call-template>
			</xsl:if>
		</xsl:if>
	</xsl:template>
	<!-- Template to add instances of NI_TDMSReference type-->
	<xsl:template name="PutTDMSReference">
		<xsl:param name="propNode"/>
		<xsl:param name="bAddPropertyToReport"/>
		<xsl:param name="nLevel"/>
		<xsl:param name="reportOptions"/>
		<xsl:param name="labelBgColor"/>
		<xsl:param name="valueBgColor"/>
		<xsl:param name="propLabel"/>
		<xsl:param name="flattenedStructure" select="false()"/>
		<xsl:param name="objectPath"/>
		<xsl:variable name="includeAttributes" select="$reportOptions/Prop[@Name = 'IncludeAttributes']/Value"/>
		<!-- Except File, if all sub-properties is empty, then NI_TDMSReference should be displayed in single line -->
		<xsl:variable name="shouldCreateContainerIfStringLengthGreaterThanZero">
			<xsl:for-each select="./Prop[@Name!='File']">
				<xsl:value-of select="./Value"/>
			</xsl:for-each>
		</xsl:variable>
		<xsl:if test="string-length($shouldCreateContainerIfStringLengthGreaterThanZero) > 0">
			<!-- Create a row for the container name and process attributes of the container -->
			<xsl:if test="$flattenedStructure = false()">
				<tr>
					<td valign="top" colspan='2'>
						<xsl:attribute name="style">border-color:<xsl:value-of select="$reportOptions/Prop[@Name='Colors']/Prop[@Name='TableBorder']/Value"/>;background-color:<xsl:value-of select="$labelBgColor"/>;width:<xsl:value-of select="$gSecondColumnWidth"/>%;</xsl:attribute>
						<span style='font-size:82%;color:{$labelBgColor};'>
							<xsl:call-template name="GetIndentationString">
								<xsl:with-param name="nLevel" select="$nLevel"/>
							</xsl:call-template>
						</span>
						<span style='font-size:82%;'>
							<xsl:value-of select="$propLabel"/>:
					</span>
					</td>
				</tr>
			</xsl:if>
			<xsl:if test="$includeAttributes = 'True'">
				<xsl:call-template name="AddAttributesToReport">
					<xsl:with-param name="reportOptions" select="$reportOptions"/>
					<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
					<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
					<xsl:with-param name="nLevel" select="$nLevel"/>
					<xsl:with-param name="flattenedStructure" select="$flattenedStructure"/>
					<xsl:with-param name="objectPath" select="$objectPath"/>
				</xsl:call-template>
			</xsl:if>
		</xsl:if>
		<xsl:variable name="filePathVariableLevel">
			<xsl:choose>
				<xsl:when test="string-length($shouldCreateContainerIfStringLengthGreaterThanZero) > 0">
					<xsl:value-of select="$nLevel + 1"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$nLevel"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<!-- Display a table row for File property -->
		<xsl:variable name="fileValue" select="./Prop[@Name='File']/Value"/>
		<xsl:choose>
			<xsl:when test="$flattenedStructure = false()">
				<tr>
					<td valign='top'>
						<xsl:attribute name="style">border-color:<xsl:value-of select="$reportOptions/Prop[@Name='Colors']/Prop[@Name='TableBorder']/Value"/>;background-color:<xsl:value-of select="$labelBgColor"/>;</xsl:attribute>
						<span style='font-size:82%;color:{$labelBgColor};'>
							<xsl:call-template name="GetIndentationString">
								<xsl:with-param name="nLevel" select="$filePathVariableLevel"/>
							</xsl:call-template>
						</span>
						<span style='font-size:82%;'>
							<!-- If being displayed in single line, use the name of the container, else use the name of sub-property -->
							<xsl:choose>
								<xsl:when test="string-length($shouldCreateContainerIfStringLengthGreaterThanZero) > 0">File:</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="$propLabel"/>:
								</xsl:otherwise>
							</xsl:choose>
						</span>
					</td>
					<td valign='top'>
						<xsl:attribute name="style">border-color:<xsl:value-of select="$reportOptions/Prop[@Name='Colors']/Prop[@Name='TableBorder']/Value"/>;background-color:<xsl:value-of select="$valueBgColor"/>;width:<xsl:value-of select="$gSecondColumnWidth" disable-output-escaping="no"/>%</xsl:attribute>
						<span style='font-size:82%;'>
							<xsl:choose>
								<xsl:when test="string-length($fileValue) &gt; 0">
									<!-- Create an hyperlink if TestStand.Hyperlink attribute is true. Otherwise treat it like a string variable -->
									<xsl:choose>
										<xsl:when test="$fileValue != '' and ./Prop[@Name='File']/Attributes/Prop[@Name='TestStand']/Prop[@Name='Hyperlink' and @Type='Boolean']/Value='True'">
											<a>
												<xsl:attribute name="href"><xsl:value-of select="$fileValue"/></xsl:attribute>
												<xsl:value-of select="$fileValue"/>
											</a>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="$fileValue"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:when>
								<xsl:otherwise>''</xsl:otherwise>
							</xsl:choose>
						</span>
					</td>
				</tr>
			</xsl:when>
			<xsl:otherwise>
				<tr>
					<td class="ReportHeader" style="white-space:nowrap">
						<b>
							<!-- If being displayed in single line, use the name of the container, else use the name of sub-property -->
							<xsl:choose>
								<xsl:when test="string-length($shouldCreateContainerIfStringLengthGreaterThanZero) > 0"><xsl:value-of select="$objectPath"/>.File:</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="$objectPath"/>:
								</xsl:otherwise>
							</xsl:choose>
						</b>
					</td>
					<td class="ReportHeader">
						<b>
							<xsl:choose>
								<xsl:when test="string-length($fileValue) &gt; 0">
									<!-- Create an hyperlink if TestStand.Hyperlink attribute is true. Otherwise treat it like a string variable -->
									<xsl:choose>
										<xsl:when test="$fileValue != '' and ./Prop[@Name='File']/Attributes/Prop[@Name='TestStand']/Prop[@Name='Hyperlink' and @Type='Boolean']/Value='True'">
											<a>
												<xsl:attribute name="href"><xsl:value-of select="$fileValue"/></xsl:attribute>
												<xsl:value-of select="$fileValue"/>
											</a>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="$fileValue"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:when>
								<xsl:otherwise>''</xsl:otherwise>
							</xsl:choose>
						</b>
					</td>
				</tr>
			</xsl:otherwise>
		</xsl:choose>
		<!-- Process attributes for the File property if NI_TDMSReference is displayed in multiple line or process attributes of container-->
		<xsl:if test="$includeAttributes='True'">
			<xsl:choose>
				<xsl:when test="string-length($shouldCreateContainerIfStringLengthGreaterThanZero) > 0">
					<xsl:for-each select="./Prop[@Name='File']">
						<xsl:call-template name="AddAttributesToReport">
							<xsl:with-param name="reportOptions" select="$reportOptions"/>
							<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
							<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
							<xsl:with-param name="nLevel" select="$filePathVariableLevel"/>
							<xsl:with-param name="flattenedStructure" select="$flattenedStructure"/>
							<xsl:with-param name="objectPath" select="concat($objectPath, '.File')"/>
						</xsl:call-template>
					</xsl:for-each>
				</xsl:when>
				<xsl:otherwise>
					<xsl:call-template name="AddAttributesToReport">
						<xsl:with-param name="reportOptions" select="$reportOptions"/>
						<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
						<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
						<xsl:with-param name="nLevel" select="$filePathVariableLevel"/>
						<xsl:with-param name="flattenedStructure" select="$flattenedStructure"/>
						<xsl:with-param name="objectPath" select="$objectPath"/>
					</xsl:call-template>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
		<!-- If NI_TDMSReference is displayed in multiple lines, then display non-empty sub-properties and process its attributes -->
		<xsl:if test="string-length($shouldCreateContainerIfStringLengthGreaterThanZero) > 0">
			<xsl:for-each select="./Prop[@Name!='File']">
				<xsl:if test="./Value!=''">
					<xsl:call-template name="GetResultLine">
						<xsl:with-param name="name" select="@Name"/>
						<xsl:with-param name="value" select="./Value"/>
						<xsl:with-param name="parentNode" select="../@Name"/>
						<xsl:with-param name="nLevel" select="$nLevel + 1"/>
						<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
						<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
						<xsl:with-param name="propNode" select="."/>
						<xsl:with-param name="flattenedStructure" select="$flattenedStructure"/>
						<xsl:with-param name="objectPath" select="concat($objectPath, '.', @Name)"/>
						<xsl:with-param name="reportOptions" select="$reportOptions"/>
					</xsl:call-template>
					<xsl:if test="$includeAttributes='True'">
						<xsl:call-template name="AddAttributesToReport">
							<xsl:with-param name="reportOptions" select="$reportOptions"/>
							<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
							<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
							<xsl:with-param name="nLevel" select="$filePathVariableLevel"/>
							<xsl:with-param name="flattenedStructure" select="$flattenedStructure"/>
							<xsl:with-param name="objectPath" select="concat($objectPath, '.', @Name)"/>
						</xsl:call-template>
					</xsl:if>
				</xsl:if>
			</xsl:for-each>
		</xsl:if>
	</xsl:template>
	<!-- XSLT Section 5.6 Template to generate a result row that will be inserted in the table.-->
	<xsl:template name="GetResultLine">
		<xsl:param name="name"/>
		<xsl:param name="value"/>
		<xsl:param name="parentNode"/>
		<xsl:param name="nLevel"/>
		<xsl:param name="labelBgColor"/>
		<xsl:param name="valueBgColor"/>
		<xsl:param name="propNode"/>
		<xsl:param name="flattenedStructure" select="false()"/>
		<xsl:param name="objectPath"/>
		<xsl:param name="reportOptions"/>
		<xsl:variable name="shouldCreateHyperlink">
			<xsl:choose>
				<xsl:when test="$value != '' and $propNode/@Type = 'String' and $propNode/@TypeName = 'Path' and $propNode/Attributes/Prop[@Name='TestStand']/Prop[@Name='Hyperlink' and @Type='Boolean']/Value = 'True'">True</xsl:when>
				<xsl:otherwise>False</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="localizedVal">
			<xsl:choose>
				<xsl:when test="$value/../@Type = 'Number' ">
					<span style="white-space:nowrap;">
					<xsl:choose>
						<xsl:when test="$reportOptions/Prop[@Name='UseLocalizedDecimalPoint']/Value = 'True' and $gLocalizedDecimalPoint != '.' ">
							<xsl:value-of select="translate($value, '.', $gLocalizedDecimalPoint)"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="$value"/>
						</xsl:otherwise>
					</xsl:choose>
					</span>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$value"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<!-- Set propLabel variable to name parameter if the name is not empty otherwise set it to the parentName parameter-->
		<xsl:choose>
			<xsl:when test="$flattenedStructure = false()">
				<xsl:variable name="propLabel">
					<xsl:choose>
						<xsl:when test="$name = 'Comp'">Comparison Type</xsl:when>
						<xsl:when test="$name != '' ">
							<xsl:value-of select="$name"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="$parentNode"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<tr>
					<td valign='top'>
						<xsl:attribute name="style">border-color:<xsl:value-of select="$labelBgColor/../../Prop[@Name='TableBorder']/Value"/>;background-color:<xsl:value-of select="$labelBgColor"/>;</xsl:attribute>
						<span style='font-size:82%;color:{$labelBgColor};'>
							<xsl:call-template name="GetIndentationString">
								<xsl:with-param name="nLevel" select="$nLevel"/>
							</xsl:call-template>
						</span>
						<span style='font-size:82%;'>
							<xsl:value-of select="$propLabel" disable-output-escaping="no"/>:
							</span>
					</td>
					<td width="{$gSecondColumnWidth}%" valign='top'>
						<xsl:attribute name="style">border-color:<xsl:value-of select="$valueBgColor/../../Prop[@Name='TableBorder']/Value"/>;background-color:<xsl:value-of select="$valueBgColor"/>;</xsl:attribute>
						<span style='font-size:82%;'>
							<xsl:choose>
								<xsl:when test="string-length($value) &gt; 0">
									<a>
										<xsl:if test="$shouldCreateHyperlink = 'True'">
											<xsl:attribute name="href">
												<xsl:value-of select="$value"/>
											</xsl:attribute>
										</xsl:if>
										<xsl:copy-of select="$localizedVal"/>
									</a>
								</xsl:when>
								<xsl:otherwise>''</xsl:otherwise>
							</xsl:choose>
						</span>
					</td>
				</tr>
			</xsl:when>
			<xsl:otherwise>
				<tr>
					<td class="ReportHeader" style="white-space:nowrap">
						<b>
							 <xsl:value-of select="$objectPath"/>: 
						</b>
					</td>
					<td class="ReportHeader">
						<b>
							<xsl:choose>
								<xsl:when test="$value != ''">
									<a>
										<xsl:if test="$shouldCreateHyperlink = 'True'">
											<xsl:attribute name="href">
												<xsl:value-of select="$value"/>
											</xsl:attribute>
										</xsl:if>
										<xsl:copy-of select="$localizedVal"/>
									</a>
								</xsl:when>
								<xsl:otherwise>''</xsl:otherwise>
							</xsl:choose>
						</b>
					</td>
				</tr>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- XSLT Section 5.7 Template to the indentation based on the level.-->
	<xsl:template name="GetIndentationString">
		<xsl:param name="nLevel"/>
		<xsl:choose>
			<xsl:when test="$nLevel &gt; 0">
				<xsl:text>___</xsl:text>
				<xsl:call-template name="GetIndentationString">
					<xsl:with-param name="nLevel" select="$nLevel - 1"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise/>
		</xsl:choose>
	</xsl:template>
	<!-- XSLT Section 5.8 Template to insert Array to the report.-->
	<xsl:template name="AddArrayToReportAsTable">
		<xsl:param name="propNode"/>
		<xsl:param name="propName"/>
		<xsl:param name="propLabel"/>
		<xsl:param name="nLevel"/>
		<xsl:param name="reportOptions"/>
		<xsl:param name="labelBgColor"/>
		<xsl:param name="valueBgColor"/>
		<xsl:param name="flattenedStructure" select="false()"/>
		<xsl:param name="objectPath"/>
		<xsl:param name="bAddLabelAndAttributes" select="true()"/>
		<xsl:variable name="valueNodes" select="./Value"/>
		<xsl:variable name="elementType" select="@ElementType"/>
		<xsl:variable name="includeAttributes" select="$reportOptions/Prop[@Name = 'IncludeAttributes']/Value"/>
		<xsl:variable name="arrayMeasurementFilter" select="user:ConvertToDecimalValue(string($reportOptions/Prop[@Name = 'ArrayMeasurementFilter']/Value))"/>
		<xsl:variable name="arrayMeasurementMax" select="user:ConvertToDecimalValue(string($reportOptions/Prop[@Name = 'ArrayMeasurementMax']/Value))"/>
		<xsl:variable name="numberOfNodes" select="count($valueNodes)"/>
		<xsl:variable name="bAddArray">
			<xsl:choose>
				<!-- Set bAddArray to False if ArrayMeasurementFilter is set to Exclude if larger than max and array size is greater than the max elements specified in the report options-->
				<xsl:when test="$arrayMeasurementFilter = 2 and $numberOfNodes > $arrayMeasurementMax ">False</xsl:when>
				<xsl:otherwise>True</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<!--variable nMax holds the number of elements that need to be added to the report-->
		<xsl:variable name="nMax">
			<xsl:choose>
				<!--If ArrayMeasurementFilter is set to Include upto Max-->
				<xsl:when test="$arrayMeasurementFilter = 1">
					<xsl:choose>
						<!--If number of array elements is less than max value set nMax to the number of elements in the array-->
						<xsl:when test="$numberOfNodes > $arrayMeasurementMax">
							<xsl:value-of select="$arrayMeasurementMax"/>
						</xsl:when>
						<!--Otherwise set nMax to the max number of elements set in the report options-->
						<xsl:otherwise>
							<xsl:value-of select="$numberOfNodes"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<!--If ArrayMeasurementFilter is set to Exclude if larger than max and number of elements is more than max set nMax to 0-->
				<xsl:when test="($arrayMeasurementFilter = 2 and $numberOfNodes > $arrayMeasurementMax)">0</xsl:when>
				<!-- If the ArrayMeasurementFilter is set to Decimate if larger than max-->
				<xsl:when test="$arrayMeasurementFilter = 3">
					<xsl:choose>
						<!-- If number of elements is greater than max set nMax equal to the maximum value set in report options-->
						<xsl:when test="$numberOfNodes > $arrayMeasurementMax">
							<xsl:value-of select="$arrayMeasurementMax"/>
						</xsl:when>
						<!-- otherwise set it to the number of elements in the array-->
						<xsl:otherwise>
							<xsl:value-of select="$numberOfNodes"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<!-- ArrayMeasurementFilter was set to Include All so set nMax to the number of array elements-->
				<xsl:otherwise>
					<xsl:value-of select="$numberOfNodes"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="doDecimation">
			<xsl:choose>
				<!-- If ArrayMeasurementFilter was set to Decimate If larger than max and if number of array elements is greater than max set in report options set bDecimate to True-->
				<xsl:when test="$arrayMeasurementFilter = 3 and $numberOfNodes > $arrayMeasurementMax">True</xsl:when>
				<xsl:otherwise>False</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="includeArrayMeasurements">
			<xsl:choose>
				<!--If IncludeArrayMeasurement is not set to Do not include arrays set includeArrayMeasurements to True. In case it is set to Include Graph and all other conditions are satisfied it would have been already handled-->
				<xsl:when test="$reportOptions/Prop[@Name = 'IncludeArrayMeasurement']/Value != '0'">True</xsl:when>
				<xsl:otherwise>False</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:choose>
			<!--handle numeric arrays-->
			<xsl:when test="$elementType = 'Number'">
				<xsl:if test="$includeArrayMeasurements = 'True'">
					<xsl:if test="$bAddArray = 'True'">
						<xsl:if test="$bAddLabelAndAttributes">
							<xsl:value-of select="concat('&lt;','tr&gt;')" disable-output-escaping="yes"/>
								<td>
									<xsl:choose>
										<xsl:when test="$flattenedStructure = false()">
											<xsl:attribute name="valign">top</xsl:attribute>
											<xsl:attribute name="style">border-color:<xsl:value-of select="$reportOptions/Prop[@Name = 'Colors']/Prop[@Name = 'TableBorder']/Value"/>;background-color:<xsl:value-of select="$labelBgColor"/></xsl:attribute>
										</xsl:when>
										<xsl:otherwise>
											<xsl:attribute name="class">ReportHeader</xsl:attribute>
											<xsl:attribute name="style">white-space:nowrap</xsl:attribute>
										</xsl:otherwise>
									</xsl:choose>
									<xsl:variable name="arraySizeString">
										<xsl:choose>
											<xsl:when test="count($valueNodes) &gt; 0">
												<!--Get the dimesion string for non empty arrays-->
												<xsl:call-template name="GetArraySizeString">
													<xsl:with-param name="lowerBound" select="@LBound"/>
													<xsl:with-param name="upperBound" select="@HBound"/>
												</xsl:call-template>
											</xsl:when>
											<xsl:otherwise>[0..empty]</xsl:otherwise>
										</xsl:choose>
									</xsl:variable>
									<xsl:choose>
										<xsl:when test="$flattenedStructure = false()">
											<span style='font-size:82%;color:{$labelBgColor};'>
												<xsl:call-template name="GetIndentationString">
													<xsl:with-param name="nLevel" select="$nLevel"/>
												</xsl:call-template>
											</span>
											<span style='font-size:82%;'>
												<xsl:value-of select="$propLabel" disable-output-escaping="no"/>
												<xsl:value-of select="$arraySizeString" disable-output-escaping="no"/>:
											</span>
										</xsl:when>
										<xsl:otherwise>
											<b><xsl:value-of select="$objectPath" disable-output-escaping="no"/>
												<xsl:value-of select="$arraySizeString" disable-output-escaping="no"/>:</b>
										</xsl:otherwise>
									</xsl:choose>
								</td>
						</xsl:if>
							<xsl:variable name="getTable">
								<xsl:choose>
									<!--getTable is set to True if IncludeArrayMeasurement is not set to Do not Include Arrays. a table might be inserted becuase of the following conditions
										1. Insert Table was selected
										2. Insert Graph was selected and Graph control was not installed.
										3. Insert Graph was selected and WinXP Security settings did not allow creating the graph control using scripting.
										4. Insert Graph was selected but array had more than 2 dimensions
									-->
									<xsl:when test="$reportOptions/Prop[@Name = 'IncludeArrayMeasurement']/Value != 0">True</xsl:when>
									<xsl:otherwise>False</xsl:otherwise>
								</xsl:choose>
							</xsl:variable>
							<xsl:call-template name="GetArrayTable">
								<xsl:with-param name="valueNodes" select="$valueNodes"/>
								<xsl:with-param name="nMax" select="$nMax"/>
								<xsl:with-param name="bDoDecimation" select="$doDecimation"/>
								<xsl:with-param name="bGetTable" select="$getTable"/>
								<xsl:with-param name="reportOptions" select="$reportOptions"/>
								<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
								<xsl:with-param name="flattenedStructure" select="$flattenedStructure"/>
								<xsl:with-param name="addTdElement" select="$bAddLabelAndAttributes"/>
								<xsl:with-param name="elementType" select="$elementType"/>
							</xsl:call-template>
						<xsl:if test="$bAddLabelAndAttributes">
							<xsl:value-of select="concat('&lt;/','tr&gt;')" disable-output-escaping="yes"/>
							<xsl:if test="$includeAttributes='True'">
								<xsl:call-template name="AddAttributesToReport">
									<xsl:with-param name="reportOptions" select="$reportOptions"/>
									<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
									<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
									<xsl:with-param name="nLevel" select="$nLevel"/>
									<xsl:with-param name="flattenedStructure" select="$flattenedStructure"/>
									<xsl:with-param name="objectPath" select="$objectPath"/>
								</xsl:call-template>
							</xsl:if>
						</xsl:if>
					</xsl:if>
				</xsl:if>
			</xsl:when>
			<!--Handle String or Boolean arrays-->
			<xsl:when test="$elementType = 'String' or $elementType = 'Boolean'">
				<xsl:if test="$includeArrayMeasurements = 'True'">
					<xsl:if test="$bAddArray = 'True'">
						<tr>
							<td>
								<xsl:choose>
									<xsl:when test="$flattenedStructure = false()">
										<xsl:attribute name="valign">top</xsl:attribute>
										<xsl:attribute name="colspan">1</xsl:attribute>
										<xsl:attribute name="style">border-color:<xsl:value-of select="$reportOptions/Prop[@Name = 'Colors']/Prop[@Name = 'TableBorder']/Value"/>;background-color:<xsl:value-of select="$labelBgColor"/></xsl:attribute>
									</xsl:when>
									<xsl:otherwise>
										<xsl:attribute name="class">ReportHeader</xsl:attribute>
										<xsl:attribute name="style">white-space:nowrap</xsl:attribute>
									</xsl:otherwise>
								</xsl:choose>
								<xsl:variable name="arraySizeString">
									<xsl:choose>
										<xsl:when test="count($valueNodes) &gt; 0">
											<!--Get array dimension string for non empty arrays-->
											<xsl:call-template name="GetArraySizeString">
												<xsl:with-param name="lowerBound" select="@LBound"/>
												<xsl:with-param name="upperBound" select="@HBound"/>
											</xsl:call-template>
										</xsl:when>
										<xsl:otherwise>[0..empty]</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								<xsl:choose>
									<xsl:when test="$flattenedStructure = false()">
										<span style='font-size:82%;color:{$labelBgColor};'>
											<xsl:call-template name="GetIndentationString">
												<xsl:with-param name="nLevel" select="$nLevel"/>
											</xsl:call-template>
										</span>
										<span style='font-size:82%;'>
											<xsl:value-of select="$propLabel" disable-output-escaping="no"/>
											<xsl:value-of select="$arraySizeString" disable-output-escaping="no"/>:
										</span>
									</xsl:when>
									<xsl:otherwise>
										<b><xsl:value-of select="$objectPath" disable-output-escaping="no"/>
											<xsl:value-of select="$arraySizeString" disable-output-escaping="no"/>:</b>
									</xsl:otherwise>
								</xsl:choose>
							</td>
							<xsl:variable name="getTable">
								<xsl:choose>
									<!--getTable is set to True if IncludeArrayMeasurement is not set to Do not Include Arrays.-->
									<xsl:when test="$reportOptions/Prop[@Name = 'IncludeArrayMeasurement']/Value != 0">True</xsl:when>
									<xsl:otherwise>False</xsl:otherwise>
								</xsl:choose>
							</xsl:variable>
							<xsl:call-template name="GetArrayTable">
								<xsl:with-param name="valueNodes" select="$valueNodes"/>
								<xsl:with-param name="nMax" select="$nMax"/>
								<xsl:with-param name="bDoDecimation" select="$doDecimation"/>
								<xsl:with-param name="bGetTable" select="$getTable"/>
								<xsl:with-param name="reportOptions" select="$reportOptions"/>
								<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
								<xsl:with-param name="flattenedStructure" select="$flattenedStructure"/>
								<xsl:with-param name="elementType" select="$elementType"/>
							</xsl:call-template>
						</tr>
						<xsl:if test="$includeAttributes='True'">
							<xsl:call-template name="AddAttributesToReport">
								<xsl:with-param name="reportOptions" select="$reportOptions"/>
								<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
								<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
								<xsl:with-param name="nLevel" select="$nLevel"/>
								<xsl:with-param name="flattenedStructure" select="$flattenedStructure"/>
								<xsl:with-param name="objectPath" select="$objectPath"/>
							</xsl:call-template>
						</xsl:if>
					</xsl:if>
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<xsl:if test="$flattenedStructure = false()">
					<tr>
						<td valign="top" colspan='2'>
							<xsl:attribute name="style">border-color:<xsl:value-of select="$reportOptions/Prop[@Name = 'Colors']/Prop[@Name = 'TableBorder']/Value"/>;background-color:<xsl:value-of select="$labelBgColor"/></xsl:attribute>
							<span style='font-size:82%;color:{$labelBgColor};'>
								<xsl:call-template name="GetIndentationString">
									<xsl:with-param name="nLevel" select="$nLevel"/>
								</xsl:call-template>
							</span>
							<span style='font-size:82%;'>
								<xsl:value-of select="$propLabel"/>:</span>
						</td>
					</tr>
				</xsl:if>
				<!--For all other types add the array and call PutFlaggedValuesInReportForArrayElements-->
				<xsl:if test="$includeAttributes='True'">
					<xsl:call-template name="AddAttributesToReport">
						<xsl:with-param name="reportOptions" select="$reportOptions"/>
						<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
						<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
						<xsl:with-param name="nLevel" select="$nLevel"/>
						<xsl:with-param name="flattenedStructure" select="$flattenedStructure"/>
						<xsl:with-param name="objectPath" select="$objectPath"/>
					</xsl:call-template>
				</xsl:if>
				<xsl:for-each select="$propNode/Value">
					<xsl:variable name="valueName" select="concat($propLabel, @ID)"/>
					<xsl:call-template name="PutFlaggedValuesInReportForArrayElements">
						<xsl:with-param name="propNodes" select="./Prop[@Flags]"/>
						<xsl:with-param name="parentPropName" select="$valueName"/>
						<xsl:with-param name="bAddPropertyToReport" select="1"/>
						<xsl:with-param name="nLevel" select="$nLevel + 1"/>
						<xsl:with-param name="reportOptions" select="$reportOptions"/>
						<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
						<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
						<xsl:with-param name="flattenedStructure" select="$flattenedStructure"/>
						<xsl:with-param name="objectPath" select="concat($objectPath, @ID)"/>
					</xsl:call-template>
				</xsl:for-each>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- Template to generate the array table.-->
	<xsl:template name="GetArrayTable">
		<xsl:param name="valueNodes"/>
		<xsl:param name="nMax"/>
		<xsl:param name="bDoDecimation"/>
		<xsl:param name="bGetTable"/>
		<xsl:param name="reportOptions"/>
		<xsl:param name="valueBgColor"/>
		<xsl:param name="addTdElement" select="true()"/>
		<xsl:param name="flattenedStructure" select="false()"/>
		<xsl:param name="elementType"/>
		<xsl:variable name="inc">
			<xsl:choose>
				<!--calculate the array increment value if bDecimation is set to True-->
				<xsl:when test="$bDoDecimation = 'True'">
					<xsl:value-of select="floor(count($valueNodes) div $nMax)"/>
				</xsl:when>
				<!--otherwise array increment is always 1-->
				<xsl:otherwise>1</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="useLocalizedDecimalPoint" select="$reportOptions/Prop[@Name = 'UseLocalizedDecimalPoint']/Value"/>
		<xsl:if test="$bGetTable = 'True'">
			<xsl:variable name="arrayValue">
				<xsl:for-each select="$valueNodes">
					<xsl:if test="(position() - 1) mod $inc = 0 and floor((position()-1) div $inc) &lt; $nMax">
						<xsl:value-of select="@ID"/> = '<xsl:choose>
							<xsl:when test="$useLocalizedDecimalPoint = 'True' and $gLocalizedDecimalPoint != '.'">
								<xsl:value-of select="translate(., '.', $gLocalizedDecimalPoint)"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="."/>
							</xsl:otherwise>
						</xsl:choose>'
						<xsl:value-of select="concat('&lt;','br /&gt;')" disable-output-escaping="yes"/>
					</xsl:if>
				</xsl:for-each>
			</xsl:variable>
			<xsl:variable name="whiteSpaceStyleValue">
				<xsl:choose>
					<xsl:when test="$elementType = 'Number'">nowrap</xsl:when>
					<xsl:otherwise>normal</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:choose>
				<xsl:when test="$addTdElement">
					<td style="white-space:{$whiteSpaceStyleValue};">
						<xsl:choose>
							<xsl:when test="$flattenedStructure = false()">
								<xsl:attribute name="valign">top</xsl:attribute>
								<xsl:attribute name="style">border-color:<xsl:value-of select="$reportOptions/Prop[@Name = 'Colors']/Prop[@Name = 'TableBorder']/Value"/>;background-color:<xsl:value-of select="$valueBgColor"/>;width:<xsl:value-of select="$gSecondColumnWidth"/>%; white-space:<xsl:value-of select="$whiteSpaceStyleValue"/>;</xsl:attribute>
								<span style='font-size:82%;'>
									<xsl:choose>
										<xsl:when test="$arrayValue != ''"><xsl:copy-of select="$arrayValue"/></xsl:when>
										<xsl:otherwise><xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text></xsl:otherwise>
									</xsl:choose>
								</span>
							</xsl:when>
							<xsl:otherwise>
								<xsl:attribute name="class">ReportHeader</xsl:attribute>
								<b>
									<xsl:choose>
										<xsl:when test="$arrayValue != ''"><xsl:copy-of select="$arrayValue"/></xsl:when>
										<xsl:otherwise><xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text></xsl:otherwise>
									</xsl:choose>
								</b>
							</xsl:otherwise>
						</xsl:choose>
					</td>
				</xsl:when>
				<xsl:otherwise>
						<xsl:choose>
							<xsl:when test="$arrayValue != ''"><xsl:copy-of select="$arrayValue"/></xsl:when>
							<xsl:otherwise><xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text></xsl:otherwise>
						</xsl:choose>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
	</xsl:template>
	<!-- Template to put flagged values in report for array elements.-->
	<xsl:template name="PutFlaggedValuesInReportForArrayElements">
		<xsl:param name="propNodes"/>
		<xsl:param name="parentPropName"/>
		<xsl:param name="bAddPropertyToReport"/>
		<xsl:param name="nLevel"/>
		<xsl:param name="reportOptions"/>
		<xsl:param name="labelBgColor"/>
		<xsl:param name="valueBgColor"/>
		<xsl:param name="flattenedStructure" select="false()"/>
		<xsl:param name="objectPath"/>
		<!--For each element of the array add the propName and propLabel and call AddIfFlagSet-->
		<xsl:for-each select="$propNodes">
			<xsl:variable name="propName" select="@Name"/>
			<xsl:variable name="propLabel">
				<xsl:choose>
					<xsl:when test="$propName">
						<xsl:value-of select="$parentPropName"/> ( <xsl:value-of select="$propName"/> )</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$parentPropName"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:call-template name="AddIfFlagSet">
				<xsl:with-param name="propNode" select="."/>
				<xsl:with-param name="propLabel" select="$propLabel"/>
				<xsl:with-param name="bAddPropertyToReport" select="$bAddPropertyToReport"/>
				<xsl:with-param name="nLevel" select="$nLevel"/>
				<xsl:with-param name="reportOptions" select="$reportOptions"/>
				<xsl:with-param name="labelBgColor" select="$labelBgColor"/>
				<xsl:with-param name="valueBgColor" select="$valueBgColor"/>
				<xsl:with-param name="flattenedStructure" select="$flattenedStructure"/>
				<xsl:with-param name="objectPath" select="$objectPath"/>
			</xsl:call-template>
		</xsl:for-each>
	</xsl:template>
	<!-- XSLT Section 5.9 Template to get the Array dimensions.-->
	<xsl:template name="GetArrayDimensions">
		<xsl:param name="dimensionString"/>
		<!--Get the array dimensions by calculating the number of [] recursively-->
		<xsl:variable name="subArrayDimensions">
			<xsl:if test="$dimensionString = ''">
				0
			</xsl:if>
			<xsl:if test="$dimensionString != ''">
				<xsl:call-template name="GetArrayDimensions">
					<xsl:with-param name="dimensionString" select="substring-after($dimensionString, ']')"/>
				</xsl:call-template>
			</xsl:if>
		</xsl:variable>
		<xsl:value-of select="1 + $subArrayDimensions"/>
	</xsl:template>
	<!-- Template to return array size string.-->
	<xsl:template name="GetArraySizeString">
		<xsl:param name="lowerBound"/>
		<xsl:param name="upperBound"/>
		<!-- Build the arraysize string by recursively parsing the lowerBound and upperBound strings-->
		<xsl:if test="$lowerBound != '' and $upperBound != ''">
			<xsl:variable name="lowerBoundVal" select="substring-before($lowerBound, ']')"/>
			<xsl:variable name="upperBoundVal" select="substring-before($upperBound, ']')"/>
				<xsl:text>[</xsl:text><xsl:value-of select="substring($lowerBoundVal, 2)" disable-output-escaping="no"/>..<xsl:value-of select="substring($upperBoundVal, 2)" disable-output-escaping="no"/><xsl:text>]</xsl:text>
				<xsl:call-template name="GetArraySizeString">
					<xsl:with-param name="lowerBound" select="substring-after($lowerBound, ']')"/>
					<xsl:with-param name="upperBound" select="substring-after($upperBound, ']')"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>
	<!-- XSLT Section 5.10 Template to return if the step failure caused the sequence to fail.-->
	<xsl:template name="GetIsCriticalFailure">
		<xsl:param name="node"/>
		<xsl:variable name="sfcsfNode" select="$node/../Prop[@Name = 'StepCausedSequenceFailure']"/>
		<xsl:choose>
			<xsl:when test="$sfcsfNode">
				<xsl:variable name="scfsfNodeText" select="$sfcsfNode/Value"/>
				<xsl:choose>
					<xsl:when test="string-length($scfsfNodeText) &gt; 0 and $scfsfNodeText = 'True'">
						<xsl:value-of select="$scfsfNodeText"/>
					</xsl:when>
					<xsl:otherwise>""</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>""</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- XSLT Section 5.11 Template to return the step background color as configured in the report options.-->
	<xsl:template name="GetStepGroupBgColor">
		<xsl:param name="node"/>
		<xsl:param name="colors"/>
		<xsl:variable name="stepGroup">
			<xsl:choose>
				<xsl:when test="$node/../Prop[@Name = 'StepGroup']/Value">
					<xsl:value-of select="$node/../Prop[@Name = 'StepGroup']/Value"/>
				</xsl:when>
				<xsl:otherwise>
					Main
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$stepGroup = 'Main'">
				<xsl:value-of select="$colors/Prop[@Name = 'MainBg']/Value" disable-output-escaping="no"/>
			</xsl:when>
			<xsl:when test="$stepGroup = 'Setup'">
				<xsl:value-of select="$colors/Prop[@Name = 'SetupBg']/Value" disable-output-escaping="no"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$colors/Prop[@Name = 'CleanupBg']/Value" disable-output-escaping="no"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>
