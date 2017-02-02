<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:user="http://www.ni.com/TestStand" xmlns:vb_user="http://www.ni.com/TestStand/" id="TS5.0.0">

<!--This alias is added so that the html output does not contain these namespaces. The omit-xml-declaration attribute of xsl:output element did not prevent the addition of these namespaces to the html output-->	
<xsl:namespace-alias stylesheet-prefix="xsl" result-prefix="#default"/>
<xsl:namespace-alias stylesheet-prefix="msxsl" result-prefix="#default"/>
<xsl:namespace-alias stylesheet-prefix="user" result-prefix="#default"/>
<xsl:namespace-alias stylesheet-prefix="vb_user" result-prefix="#default"/>

	<!--VBScript Section: Contains only one function GetLocalizedDecimalPoint().This function will return the localized decimal point for a decimal number.-->
	<msxsl:script language="VBScript" implements-prefix="vb_user">
	<![CDATA[
		'This function will return the localized decimal point for a decimal number
		Function GetLocalizedDecimalPoint ()
			dim lDecPoint
			lDecPoint = Mid(CStr(1.1),2,1)
			GetLocalizedDecimalPoint = lDecPoint
		End Function
	]]>
	</msxsl:script>
	<msxsl:script language="javascript" implements-prefix="user">
	<![CDATA[
	// Global Variables 
	var gIndentTables = true; // indent tables or not for SequenceCall results
	var gStoreStylesheetAbsolutePath = 1; 
	
	// Report Options global variables
	var gIncludeArrayMeasurement = 0;
	var gArrayMeasurementFilter = 0;
	var gArrayMeasurementMax = 0;
	var gIncludeTimes = 0;
	var gUseLocalizedDecimalPoint = 0;
	var gLocalizedDecimalPoint = "";
	var gSecondColumnSpan6 = 6;
	var gNumericFormatRadix = 10;
	var gNumericFormatSuffix = "";
	
	//Javascript Section 1: Adding report options to global information
	// This function initializes the base or prefix path global variables
	function InitStylesheetPath(nodelist)
	{
		var reportOptionsNode = nodelist.item(nodelist.length-1);
		var stylesheetPath = reportOptionsNode.selectSingleNode("Prop[@Name='StylesheetPath']/Value").text;
		var storeStylesheetAbsolutePath = reportOptionsNode.selectSingleNode("Prop[@Name='StoreStylesheetAbsolutePath']/Value").text;
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
		
	// This function initializes all report options flag global variables
	function InitFlagGlobalVariables(nodelist)
	{
		var reportOptionsNode = nodelist.item(0);
		
		gIncludeArrayMeasurement = ConvertToDecimalValue(reportOptionsNode.selectSingleNode("Prop[@Name='IncludeArrayMeasurement']/Value").nodeTypedValue);
		gArrayMeasurementFilter = ConvertToDecimalValue(reportOptionsNode.selectSingleNode("Prop[@Name='ArrayMeasurementFilter']/Value").nodeTypedValue);
		gArrayMeasurementMax = ConvertToDecimalValue(reportOptionsNode.selectSingleNode("Prop[@Name='ArrayMeasurementMax']/Value").nodeTypedValue);
		gIncludeTimes = (reportOptionsNode.selectSingleNode("Prop[@Name='IncludeTimes']/Value").nodeTypedValue == 'True') && 
			(reportOptionsNode.selectSingleNode("Prop[@Name='IncludeStepResults']").nodeTypedValue == 'True');
		var useLocalizedDecimalPointNode = reportOptionsNode.selectSingleNode("Prop[@Name='UseLocalizedDecimalPoint']");
		// Do this so that old reports can also use the new style sheet
		if (useLocalizedDecimalPointNode)
			gUseLocalizedDecimalPoint = (reportOptionsNode.selectSingleNode("Prop[@Name='UseLocalizedDecimalPoint']/Value").nodeTypedValue == 'True');
		return "";
	}

	function SetColumnSpanConstant(colSpan6)
	{
		gSecondColumnSpan6 = colSpan6;
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
		var localizedNode = node ? node.text: "";
		if (gUseLocalizedDecimalPoint)
		{
			var tempNode = node ? node.text: "";
			if (tempNode)
				localizedNode = tempNode.replace(".", gLocalizedDecimalPoint)
		}
		return localizedNode;
	}

	//Javascript Section 3: Functions to handle indentation and block levels for the tables in the report.
	var gResultLevel = -1;
	var gBlockLevelArray;
	var gIndentationWidth = 40;
	var gIndentationLevel = 0;
	var gAddTable = 1;
	var gMaxBlockLevel = 100; // This is the max blockLevel supported in the report
	
	// This method returns the indentation level
	function GetIndentationLevel()
	{
		return gIndentationLevel;
	}
	
	// This method sets the indentation for the sequence call results based on the global indentation variable
	function SetSequenceCallIndentationLevel(curIndentationLevel)
	{
		if(gIndentTables == true)
			gIndentationLevel = curIndentationLevel;
		
		return "";
	}
	
	// This method sets the indentation level for flow control steps
	function SetIndentationLevel(curIndentationLevel)
	{
		gIndentationLevel = curIndentationLevel;
		return "";
	}
	
	// This method returns the indentation width for table elements
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
		var sRet = "";
		var node = nodelist.item(0);
		var node1 = node.selectSingleNode("Prop[@Name='TS']/Prop[@Name='BlockLevel']");
		var curStepBlockLevel  = -1;
		if (node1)
			curStepBlockLevel = ConvertToDecimalValue(node.selectSingleNode("Prop[@Name='TS']/Prop[@Name='BlockLevel']/Value").nodeTypedValue);

		if( curStepBlockLevel == -1)
			return sRet;
		
		if (curStepBlockLevel != GetBlockLevel())
		{
			// Close current table
			if(GetAddTable() == '0')
				sRet = EndTable();
			
			SetIndentationLevel(GetIndentationLevel() + parseInt(curStepBlockLevel - GetBlockLevel(), 10));
			SetBlockLevel(curStepBlockLevel);
		}
		
		// add Start table
		if(GetAddTable() == '1' && (!gEnableResultFiltering || CheckIfStepSatisfiesFilteringCondition_node(node)))
			sRet += BeginTable();
			
		return (sRet + "\n");
	}
	
	// This function generates an indentation string based on the block level
	function GetIndentationString(nLevel)
	{
		var sIndent = "";
		for (var i = 0; i < nLevel; i++)
			sIndent += GetStdIndentationString();
		
		return sIndent;
	}

	function GetAddTable()
	{
		return gAddTable;
	}
	
	function SetAddTable(tableToBeAdded)
	{
		gAddTable = tableToBeAdded;
		return "";
	}

	function GetStdIndentationString()
	{
		return "&nbsp;&nbsp;";
	}
		
	// This function returns indentaion string if the step is a loop result 
	function GetInitialIndentation(nodelist)
	{
		var isLoopResultStepName = GetLoopIndex(nodelist);
		var sRet = "";
		if (isLoopResultStepName != "")
			sRet = GetIndentationString(2);
		
		return sRet;
	}

	//Javascript Section 4: Functions to insert 'looping' step results into the report
	// This function initializes the global array used to store loop index counts
	var gLoopNodeArray;
	var gLoopCounterArray;
	var gFirstLoopIndexArray;
	var gLoopStackDepth = -1;
	function InitLoopArray(nodelist)
	{
		var node = nodelist.item(0);
		var loopStartNodes = node.selectNodes(".//Prop[@Name='NumLoops']")
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

	// This function returns the html for the Table Row of the Loop Indices
	function GetLoopIndicesTableEntry(node)
	{
		var stepName = node.selectSingleNode("Prop[@Name='TS']/Prop[@Name='StepName']/Value").nodeTypedValue;
		var stepGroup = node.selectSingleNode("Prop[@Name='TS']/Prop[@Name='StepGroup']/Value").nodeTypedValue;
		var sRet = "";
		sRet += "<tr>";
		sRet += "<td colspan='1'>";
		sRet += GetStdIndentationString();
		sRet += "<span style='font-size:0.6em'>" + stepName + " (Loop Indices)</span></td>\n";
		sRet += "<td colspan='" + gSecondColumnSpan6 +"'>&nbsp;</td>\n";
		sRet += "</tr>\n";
		return sRet;
	}
	
	// This function checks to see if this is the first loop step result.  If yes,it increments the loop stack depth counter.
	function TestForStartLoopIndex()
	{
		if (gFirstLoopIndexArray[gLoopStackDepth + 1])
		{
			var node;
			var id;
			gLoopStackDepth++;
			gFirstLoopIndexArray[gLoopStackDepth] = false;
			node = gLoopNodeArray[gLoopStackDepth];
			id = node.selectSingleNode("Prop[@Name='TS']/Prop[@Name='Id']/Value").nodeTypedValue;
			return GetLoopIndicesTableEntry(node);
		}
		else
			return "";
	}
		
	// This function checks to see if all loop step results have been seen.  If yes, it decreases the loop stack depth counter.
	function TestForEndLoopIndex()
	{
		if (--gLoopCounterArray[gLoopStackDepth] == 0)
		{
			gLoopNodeArray[gLoopStackDepth] = null;
			gLoopStackDepth--;
		}
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
	function GraphArray (sLBound, sHBound)
	{
		this.LBoundElements = (sLBound.substring(1).replace(/]/g,"")).split("[");
		this.HBoundElements = sHBound.substring(1).replace(/]/g,"").split("[");
		this.Dimensions = sLBound.split("[").length - 1;

		this.SizeString = "";
		var i = 0;
		
		for (i = 0; i < this.LBoundElements.length; ++i)
			this.SizeString += "[" + this.LBoundElements[i] + ".." + this.HBoundElements[i] + "]";
		
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
			this.Graphs[i] = new Array();
		//GraphArray methods:
		this.AddElementToGraph = AddElementToGraph;
		this.GetGraphData = GetGraphData;
		this.Get2DArrayData = Get2DArrayData;
	}

	function AddElementToGraph(element)
	{
		if(this.Dimensions == 1)
			this.Graphs[0].push(element.text);
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
	function Get2DArrayData(inc, colBasedDecimate)
	{
		var sRet = "";
		var i = 0;
		var j = 0;
		var rowInc = inc;
		var colInc = inc;
    
		if (colBasedDecimate)
      		colInc = 1;
		else
      		rowInc = 1;
    
		sRet += "Array( Array(";

		for(i = 0; i < this.NumberOfGraphs; i += rowInc)
		{
			if (i  >0)
				sRet += ", Array(";
			for (j = 0; j < this.Graphs[i].length; j += colInc)
			{
				if (j> 0)
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
  
	function GetArrayGraph(valueNodes, nMax, bDoDecimation, graphArrayObj, sDataLayout, sDataOrientation)
	{
		var sRet = "";
		var inc = (bDoDecimation) ? (valueNodes.length / nMax) : 1;
		var n = 0;
		var i = 0;
		var valueNode = valueNodes.item(0);
        var colBasedDecimate = false;
	
		sRet += "<td colspan='6'>";
		if(graphArrayObj.Dimensions == 2)
		{																 
			if (sDataOrientation.toLowerCase() == "column based")
				colBasedDecimate = true;

			//this is to fix the decimation to each graph
		    if (colBasedDecimate == true)
                nMax = nMax * graphArrayObj.NumberOfColPlots;
            else
			    nMax = nMax * graphArrayObj.NumberOfGraphs;

			inc = (bDoDecimation) ? (graphArrayObj.GraphSize / nMax) : 1;
		}

		inc = Math.floor(inc); 
		
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
			sRet += gGraphCount + "' height='200' style='left: 0px; top: 0px' width='100%'> </object>";
			sRet += "<script defer type='text/vbscript'>";
			if (graphArrayObj.Dimensions == 1)
					sRet += " Call CWGRAPH" + gGraphCount + ".PlotY(Array(" + graphArrayObj.GetGraphData(0) + "), 0, " + inc + ") \n";
			else // 2D arrays
				sRet += " Call CWGRAPH" + gGraphCount + ".Plot2DArrayData( " + graphArrayObj.Get2DArrayData(inc, colBasedDecimate) +  ",\"" + sDataLayout + "\", \"" + sDataOrientation + "\", " + "\"True\"" + ", "+ inc + ")\n";

      sRet += "</script>";
			gGraphCount++;
		}
		else
			sRet += "&nbsp;";
		
		sRet += "</td>\n";
		return sRet;
	}
			
	var GRAPH_ATTRIBUTES_DATALAYOUT_XPATH = "Attributes/Prop[@Name='TestStand']/Prop[@Name='DataLayout']/Value";
	var GRAPH_ATTRIBUTES_DATAORIENTATION_XPATH = "Attributes/Prop[@Name='TestStand']/Prop[@Name='DataOrientation']/Value";

  // This function adds an array to the report as a graph (the elements will be numbers) and 
	// as individual values otherwise
	function AddArrayToReportAsGraph (propNodes, propName, propLabel, nLevel, flattenedStructure, objPath)
	{
		var sRet = "";
		var nMax = 0;
		var bAddArray = true;
		var bDoDecimation = false;
		var propNode = propNodes.item(0);
		var valueNodes = propNode.selectNodes("Value");
		var dataLayoutNode = propNode.selectNodes(GRAPH_ATTRIBUTES_DATALAYOUT_XPATH);
		var dataOrientationNode = propNode.selectNodes(GRAPH_ATTRIBUTES_DATAORIENTATION_XPATH);
		var sDataLayout  = "";
		var sDataOrientation = "";

		if(dataLayoutNode[0])
			sDataLayout = dataLayoutNode[0].text;
		if (dataOrientationNode[0])
			sDataOrientation = dataOrientationNode[0].text;

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
				var sArray = GetArrayGraph (valueNodes, nMax, bDoDecimation, graphArrayObj, sDataLayout, sDataOrientation);
				// Add Label
				sRet += "<tr><td valign='top'>";
	
				if (!flattenedStructure)
				{
					if (valueNodes.length > 0)
						sRet += "<span style='font-size:0.6em'>" + GetIndentationString(nLevel) + propLabel + graphArrayObj.SizeString + ":" + "</span>" + "</td>\n";
					else
						sRet += "<span style='font-size:0.6em'>" + GetIndentationString(nLevel) + propLabel + "[0.." + "empty" + "]" + ":" + "</span>" + "</td>\n";
				}
				else
				{
					if (valueNodes.length > 0)
						sRet += "<span style='font-size:0.6em'> <b>" + objPath + graphArrayObj.SizeString + ": </b> </span>" + "</td>\n";
					else
						sRet += "<span style='font-size:0.6em'> <b>" + objPath + "[0.." + "empty" + "]" + ": </b> </span>" + "</td>\n";
				}
					
				// Add Array Graph
				sRet += sArray;
				sRet += "</tr>\n";
			}
		}
		return sRet;
	}

	//Javascript Section 6: Functions to insert tables into the report
	//This function adds a begin Table Element.
	function BeginTable()
	{
		SetAddTable(0);
		return	"\n<table style='margin-left:" + (GetIndentationLevel() * gIndentationWidth).toString(10) + "px;' border='1' cellpadding='2' cellspacing='0' width='70%'>" +
				"<tr>" + 
				"<td rowspan='2' valign='bottom' align='center' style='width:30%'><span style='font-size:0.6em'><b>Step</b></span></td>\n" +
				"<td rowspan='2' valign='bottom' align='center' style='width:6%'><span style='font-size:0.6em'><b>Status</b></span></td>\n" +
				"<td rowspan='2' valign='bottom' align='center' style='width:10%'><span style='font-size:0.6em'><b>Measurement</b></span></td>\n" + 
				"<td rowspan='2' valign='bottom' align='center' style='width:7%'><span style='font-size:0.6em'><b>Units</b></span></td>\n" +
				"<td colspan='3' align='center' style='width:33%'><span style='font-size:0.6em'><b>Limits</b></span></td>\n" +
				//CREATE_EXTRA_COLUMNS: Users needs to add extra columns here if needed. The data for the 
				//columns need to be added in ADD_COLUMN_DATA_1 to ADD_COLUMN_DATA_13.
				//Ex:To add another column having 'Extra information' as the column header
				//"<td rowspan='2' valign='bottom' align='center' style='width:30%'><span style='font-size:0.6em'><b>StepID</b></span></td>\n" +
				"</tr>\n" +
				"<tr>" + 
				"<td style='width:10%' align='center'><span style='font-size:0.6em'><b>Low Limit</b></span></td>\n" +
				"<td style='width:10%' align='center'><span style='font-size:0.6em'><b>High Limit</b></span></td>\n" + 
				"<td style='width:13%' align='center'><span style='font-size:0.6em;white-space:nowrap'><b>Comparison Type</b></span></td>\n" + 
				"</tr>\n"; 
	}
				
	//This function adds an ending Table Element.
	function EndTable()
	{
		SetAddTable(1);	
		return "</table><br>";
	}

	//Function is called when filtering certain steps from the report being displayed. This function returns true 
	//if a step in the called sequence satisfies the filtering condition and the step blockLevel is 0 i.e. no flow control
	//step or sequence call was present in between.
	//Returns true if a new table should be created
	function IsTableCreationNecessary(nodeList)
	{
		var count = nodeList.length;
		var i = 0;
		for ( i=0 ; i< count; i++ )
		{
			var blockLevelPropObject = nodeList.item(i).selectSingleNode("Prop[@Name='TS']/Prop[@Name='BlockLevel']");		
			var blockLevel;
			if(blockLevelPropObject == null)
				blockLevel = GetBlockLevel();
			else	
				blockLevel = ConvertToDecimalValue( blockLevelPropObject.selectSingleNode("Value").nodeTypedValue);
			
			if (blockLevel == 0 && CheckIfStepSatisfiesFilteringCondition_node(nodeList.item(i)))
				return true;
			else if (blockLevel == 1)//If you encounter a step with block level 1 return false. a new table will be created for this step and will be handled later.
				return false;
		}
		return false;
	}	
	
	//Javascript Section 7: Utility functions.    
	//This function return the list item for the total time of the UUT in HH:MM:SS format
	//Example code to change the display format of the total execution time. Uncomment if using the example template.
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
			
			return  "<tr valign='top'><td style='white-space:nowrap'><span style='font-size:0.6em'><b>Execution Time</b></span></td><td style='white-space:nowrap'><span style='font-size:0.6em'>" + ((text == '') ? "N/a" : totalSec) + "</span></td></tr>\n";
		}
		else
			return "&nbsp;"; 
	}
	
	function ResetBlockLevel()
	{
		SetIndentationLevel(GetIndentationLevel() - GetBlockLevel());
		SetBlockLevel(0);
		return "";
	}
	
	// This function returns the serial number of the input node or returns the string NONE
	function GetSerialNumber(nodelist)
	{
		var node = nodelist.item(0);
		var text = node ? node.text : "";
		return GetSerialNumberFromText (text);
	}
    
    //This function returns &nbsp if the serial number only contains white spaces, returns the string NONE if the serial number is empty or returns the serial number.
    function GetSerialNumberFromText(text)
    {
		var pattern = /\s+/;
		if (text == text.match(pattern))
			return "&nbsp;";
		else
			return (text == "") ? "NONE" : text;
    }
    
	// This function returns the Id value of the input result node 
	function GetResultId(nodelist)
	{
		var node = nodelist.item(0);
		var idNode = node.parentNode.selectSingleNode("Prop[@Name='Id']");
		return (idNode != null) ? idNode.selectSingleNode("Value").text : "";
	}
	
	// This function returns the loop index text or null if LoopIndex isnt found
	function GetLoopIndex(nodelist)
	{
		var node = nodelist.item(0);
		var valueNode = node.parentNode.selectSingleNode("Prop[@Name='LoopIndex']/Value");
		var sRet = "";
		if (valueNode != null)
			sRet = " (Loop Index: " + valueNode.text + ")";
			
		return sRet;
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
			var stepTypeText = stepType?stepType.text:"";
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
	
		// remove white space 
		var tempNode = "";
		tempNode = sRet.replace(/^\s+/,'');
		if (tempNode == "")
			tempNode = "&nbsp;"
		sRet = tempNode;
		
		return sRet;
	}	
	
	// This function returns either the (full) file URL or only the file name depending if storing absolute
	// or relative path to the stylesheet
	function GetLinkURL(nodelist)
	{
		var node = nodelist.item(0);
		return (gStoreStylesheetAbsolutePath) ? node.getAttribute("URL") : node.getAttribute("FileName");
	}

	function AddPropertyToReport(propNodes, bAddPropertyToReport, bIncludeMeasurement, bIncludeLimits)
	{
		var prop = propNodes.item(0);
		var propFlags = prop.getAttribute('Flags');
		var bIncludeInReport = ((propFlags & 0x2000) == 0x2000);
		var bIsMeasurementValue = ((propFlags & 0x0400) == 0x0400);
		var bIsLimitValue = ((propFlags & 0x1000) == 0x1000);

		if((bAddPropertyToReport || bIncludeInReport) && 
			!((bIsMeasurementValue && bIncludeMeasurement != 'True') || (bIsLimitValue && bIncludeLimits != 'True')) )
			return true;
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
	
	//JavaScript Section 8: None
		
	//JavaScript Section 9: Functions to support report filtering
	//Global variable to indicate whether report filtering is ON/OFF	
	var gEnableResultFiltering = true;
	//Function to check whether a table needs to be created for a sequence call step.
	function BeginTableForSequence(nodeList)
	{
		if(!gEnableResultFiltering || IsTableCreationNecessary(nodeList))
		{
			SetSequenceCallIndentationLevel(GetIndentationLevel() + 1);
			return BeginTable();
		}
		else
			return "";
	}
	
	//Function to check and add an end table tag for a sequence call.
	function EndTableForSequence(nodeList)
	{
		if(!gEnableResultFiltering || (IsTableCreatedForSequence(nodeList) && GetAddTable() == 0))
		{
			SetSequenceCallIndentationLevel(GetIndentationLevel() - 1);
			return EndTable();
		}
		else
			return "";
	}
	
	//Function is called when filtering certain steps from the report being displayed
	//Returns true if a new table should be created
	function IsTableCreatedForSequence(nodeList)
	{
		var count = nodeList.length;
		var i = 0;
		
		for ( i=0 ; i< count; i++ )
		{
			if (CheckIfStepSatisfiesFilteringCondition_node(nodeList.item(i)))
				return true;
		}
		return false;
	}
		
	//Function to set/reset the Report filtering flag.  
	function SetEnableResultFiltering(enableResultFiltering)
	{
		gEnableResultFiltering = enableResultFiltering == "1" ?  true : false;
		return "";
	}
   
	//Function to test whether a step satisfies the filtering condition.
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
	<xsl:variable name="gUnsavedSeqFileName" >
		<xsl:text>Unsaved Sequence File</xsl:text>
	</xsl:variable>
	<!-- a variable to keep track of whether the required Graph control is installed on the system -->
	<xsl:variable name="gGraphControlInstalled" select="user:IsGraphControlInstalled()"/>
	<!-- a global variable to hold the character that represents the localized decimal point-->
	<xsl:variable name="gLocalizedDecimalPoint" select="vb_user:GetLocalizedDecimalPoint()"/>
	<!--A global variable to switch report filtering ON/OFF. 0 -> filtering OFF and 1 -> filtering ON-->
	<xsl:variable name="gEnableResultFiltering">0</xsl:variable>
	<!--A global variable to hold the empty string representation -->
	<xsl:variable name="emptyCellValue">
		<xsl:call-template name="GetEmptyCellValue"/>
	</xsl:variable>
	<!-- XSLT Section 1 Initiate the creation of the html page	-->
	<!-- INITIALIZE_COLUMN_SPAN_VARIABLES: Section that initialize  global column span variables -->
	<xsl:variable name="gSecondColumnSpan5" select="5"/>
	<xsl:variable name="gSecondColumnSpan6" select="6"/>
	<xsl:variable name="gSecondColumnSpan7" select="7"/>
	<xsl:variable name="gSecondColumnSpan8" select="8"/>
	<xsl:template match="/">
		<html>
			<head>
				<title>XML Report</title>
				<style type="text/css">
					h4{margin-bottom:0px;padding-bottom:0px;white-space:nowrap;}
					hr{width:87%;height:2px;text-align:left;margin-left:0;color:lightgray;background-color:lightgray;border-style:groove;}
					body { margin: 0px; }
					@import url(http://fonts.googleapis.com/css?family=Open+Sans);
					.header {margin:0px; margin-bottom: 10px; background: #F2F2F2;}
					.header .centered { max-width: 970px; min-width: 600px; margin-left: auto; margin-right:auto; margin-top: 0px; margin-bottom:0px; }
					.centered img { display: block; border: 10px solid #F2F2F2; }
					.retest { margin: 6px; }
					.UUTreport { margin: 6px; }
				</style>

				<xsl:if test="//Report">
					<xsl:value-of select="user:InitStylesheetPath(//Report/Prop[@Name='ReportOptions'])"/>
					<xsl:value-of select="user:SetLocalizedDecimalPoint(vb_user:GetLocalizedDecimalPoint())"/>
					<xsl:value-of select="user:SetColumnSpanConstant(number($gSecondColumnSpan6))"/>
					<xsl:value-of select="user:SetEnableResultFiltering(string($gEnableResultFiltering))"/>
				</xsl:if>
			</head>
			<body style="font-family:verdana;font-size:100%;">
				<div class="header">
					<div class="centered">
						<img src="http://www.rtlogic.com/~/media/images/logos/rtlogic-logo.png" border="0" align="center" />
					</div>
				</div>
				<!-- ADD_HEADER_INFO: Section to add header Text/Image 
					<img src = 'c:\Images\CompanyLogo.jpg'/>
					<span style="font-size:1.13em;color:#003366;">Computer Motherboard Test</span>
				-->
				<xsl:apply-templates select="//retest"/>
				<xsl:apply-templates select="//Report"/>
				<!-- ADD_FOOTER_INFO: Section to add footer Text/Image to the entire report
					<span style = "font-family:arial;color:#003366;">TestStand Generated Report</span>
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
	
	<!-- XSLT Section 2: Templates to process UUT report	-->
	<!-- XSLT Section 2.1: Templates to process <Report> tag of type 'UUT'	-->
	<xsl:template match="Report[@Type='UUT']">
		<xsl:variable name="reportOptions" select="Prop[@Name='ReportOptions']"/>
		<xsl:value-of select="user:InitNumericFormatRadix(Prop[@Name='ReportOptions'])"/>
		<xsl:value-of select="user:InitFlagGlobalVariables(Prop[@Name='ReportOptions'])"/>
		<xsl:value-of select="user:InitLoopArray(.)"/>
		<xsl:value-of select="user:InitBlockLevelArray()"/>
		<xsl:value-of select="user:InitLoopingInfoArray()"/>
		<xsl:variable name="shouldDisplayTestSocketIndex">
			<xsl:value-of select="not(user:IsValueMinusOne(string(Prop[@Name='UUT']/Prop[@Name='TestSocketIndex']/Value)))"/>
		</xsl:variable>
		<div class="UUTreport">
			<a>
				<xsl:attribute name="name"><xsl:value-of select="@Link"/></xsl:attribute>
			</a>
			<h3>
				<span style='font-size:0.7em'>
					<xsl:value-of select="@Title"/>
				</span>
			</h3>
			<!-- CREATE_UUT_REPORT_HEADER : Section to process the UUT report header table	-->
			<table border="1" cellpadding="2" cellspacing="0" width="70%" class="UUTreport">
				<xsl:apply-templates select="Prop[@Name='StationInfo']/Prop[@Name='StationID']"/>
				<xsl:apply-templates select="Prop[@Name='UUT']/Prop[@Name='BatchSerialNumber']"/>
				<xsl:apply-templates select="Prop[@Name='UUT']/Prop[@Name='TestSocketIndex']"/>
				<xsl:apply-templates select="Prop[@Name='UUT']/Prop[@Name='SerialNumber']"/>
				<xsl:apply-templates select="Prop[@Name='StartDate']"/>
				<xsl:apply-templates select="Prop[@Name='StartTime']"/>
				<xsl:apply-templates select="Prop[@Name='StationInfo']/Prop[@Name='LoginName']"/>
				<xsl:apply-templates select="Prop/Prop[@Name='TS']/Prop[@Name='TotalTime']">
					<xsl:with-param name="reportOptions" select="$reportOptions"/>
				</xsl:apply-templates>
				<tr valign="top">
					<td style="white-space:nowrap">
						<span style='font-size:0.6em'>
							<b>Number of Results</b>
						</span>
					</td>
					<td style='white-space:nowrap'>
						<span style='font-size:0.6em'>
							<xsl:value-of select="@StepCount"/>
						</span>
					</td>
				</tr>
				<tr valign="top">
					<td style="white-space:nowrap">
						<span style='font-size:0.6em'>
							<b>UUT Result</b>
						</span>
					</td>
					<td style='white-space:nowrap'>
						<span>
							<xsl:attribute name="style">font-size:0.6em;color:<xsl:call-template name="GetStatusColor">
									<xsl:with-param name="colors" select="$reportOptions/Prop[@Name = 'Colors']"/>
									<xsl:with-param name="status" select="@UUTResult"/>	
								</xsl:call-template></xsl:attribute>
								<xsl:choose>
								<xsl:when test="string(@UUTResult) != ''">
									<xsl:value-of select="@UUTResult"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:call-template name="GetEmptyCellValue"/>
								</xsl:otherwise>
							</xsl:choose>
						</span>
					</td>
				</tr>
				<xsl:apply-templates select="Prop[@Name='UUT']/Prop[@Name='PartNumber']"/>
				<xsl:apply-templates select="Prop[@Name='TSRData']/Prop[@Name='TSRFileName']"/>
				<xsl:apply-templates select="Prop[@Name='TSRData']/Prop[@Name='TSRFileID']"/>
				<xsl:apply-templates select="Prop[@Name='TSRData']/Prop[@Name='TSRFileClosed']"/>
	<!-- ADD_UUTHEADER_INFO: Section to insert data to the new column created in section CREATE_UUTHEADER_INFO
				<tr valign="top">
					<td style="white-space:nowrap">
						<span style='font-size:0.6em'>
							<b>Type of Report</b>
						</span>
					</td>
					<td style='white-space:nowrap'>
						<span>
							<xsl:attribute name="style">font-size:0.6em;</xsl:attribute>
							<xsl:value-of select="@Type"/>
						</span>
					</td>
				</tr>	
					-->
				<xsl:if test="ErrorText">
					<tr valign="top">
						<td style="white-space:nowrap" colspan="2">
							<span>
								<xsl:attribute name="style">font-size:0.6em;color:<xsl:call-template name="GetStatusColor">
										<xsl:with-param name="colors" select="$reportOptions/Prop[@Name = 'Colors']"/>
										<xsl:with-param name="status" select='string("Error")'/>
									</xsl:call-template></xsl:attribute>
								Error: <xsl:value-of disable-output-escaping="yes" select="user:RemoveIllegalCharacters(ErrorText)"/>
							</span>
						</td>
					</tr>
				</xsl:if>
			</table>
			<br/>
			<xsl:if test="Prop[@Name='UUT']/Prop[@Name='CriticalFailureStack']/Value">
				<table border="1" cellspacing="0" cellpadding="2" width="70%">
					<tbody>
						<tr>
							<td style='white-space:nowrap' colspan="3" align="center">
								<span style='font-size:0.6em'>
									<b>Failure Chain </b>
								</span>
							</td>
						</tr>
					</tbody>
					<xsl:apply-templates select="Prop[@Name='UUT']/Prop[@Name='CriticalFailureStack']"/>
				</table><br/>
			</xsl:if>
		</div>
		<hr/>
		<br/>
		<xsl:apply-templates select="Prop/Prop[@Name='TS']/Prop[@Name='SequenceCall']">
			<xsl:with-param name="reportOptions" select="$reportOptions"/>
		</xsl:apply-templates>
		<xsl:if test="Prop/Prop[@Name='TS']/Prop[@Name='SequenceCall']/Prop[@Name='ResultList'] and count(Prop/Prop[@Name='TS']/Prop[@Name='SequenceCall']/Prop[@Name='ResultList']/Value) = 0">
			<h3>
				<span style="font-size:0.6em;">
					No Sequence Results Found
				</span>
			</h3>
			</xsl:if>
		<h3>
			<span style='font-size:0.7em'>
				End UUT Report
			</span>
		</h3>
		<hr/>
	</xsl:template>
	<!-- XSLT Section 2.2: Templates to get data to be added into the UUT report header-->
	<xsl:template match="Prop[@Name='BatchSerialNumber']">
		<xsl:if test="Value != ''">
			<tr valign="top">
				<td style="white-space:nowrap">
					<span style='font-size:0.6em'>
						<b>Batch Serial Number</b>
					</span>
				</td>
				<td style='white-space:nowrap'>
					<span style='font-size:0.6em'>
						<xsl:value-of disable-output-escaping="yes" select="user:GetSerialNumber(Value)"/>
					</span>
				</td>
			</tr>
		</xsl:if>
	</xsl:template>
	<xsl:template match="Prop[@Name='TestSocketIndex']">
		<xsl:variable name="shouldDisplayTestSocketIndex">
			<xsl:value-of select="not(user:IsValueMinusOne(string(Value)))"/>
		</xsl:variable>
		<xsl:if test="$shouldDisplayTestSocketIndex = 'true'">
			<tr valign="top">
				<td style="white-space:nowrap">
					<span style='font-size:0.6em'>
						<b>Test Socket Index</b>
					</span>
				</td>
				<td style='white-space:nowrap'>
					<span style='font-size:0.6em'>
					<xsl:choose>
						<xsl:when test="string(Value) != ''">
							<xsl:value-of select="Value"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:call-template name="GetEmptyCellValue"/>
						</xsl:otherwise>
					</xsl:choose>
					</span>
				</td>
			</tr>
		</xsl:if>
	</xsl:template>
	<xsl:template match="Prop[@Name='TSRFileName']">
		<xsl:if test="Value != ''">
			<tr valign="top">
				<td style="white-space:nowrap">
					<span style='font-size:0.6em'>
						<b>TSR File Name</b>
					</span>
				</td>
				<td style='white-space:nowrap'>
					<span style='font-size:0.6em'>
						<xsl:value-of select="Value"/>
					</span>
				</td>
			</tr>
		</xsl:if>
	</xsl:template>
	<xsl:template match="Prop[@Name='TSRFileID']">
		<xsl:if test="Value != ''">
			<tr valign="top">
				<td style="white-space:nowrap">
					<span style='font-size:0.6em'>
						<b>TSR File ID</b>
					</span>
				</td>
				<td style='white-space:nowrap'>
					<span style='font-size:0.6em'>
						<xsl:value-of select="Value"/>
					</span>
				</td>
			</tr>
		</xsl:if>
	</xsl:template>
	<xsl:template match="Prop[@Name='TSRFileClosed']">
		<xsl:if test="Value != ''">
			<tr valign="top">
				<td style="white-space:nowrap">
					<span style='font-size:0.6em'>
						<b>TSR File Closed</b>
					</span>
				</td>
				<td style="white-space:normal">
					<span style='font-size:0.6em'>
						<xsl:choose>
							<xsl:when test="Value = 'True'">OK</xsl:when>
							<xsl:otherwise>The .tsr file was not closed normally when written. This can indicate that the testing process was interrupted or aborted.</xsl:otherwise>
						</xsl:choose>
					</span>
				</td>
			</tr>
		</xsl:if>
	</xsl:template>
	<xsl:template match="Prop[@Name='PartNumber']">
		<xsl:if test="Value != ''">
			<tr valign="top">
				<td style="white-space:nowrap">
					<span style='font-size:0.6em'>
						<b>Part Number</b>
					</span>
				</td>
				<td style='white-space:nowrap'>
					<span style='font-size:0.6em'>
						<xsl:value-of select="Value"/>
					</span>
				</td>
			</tr>
		</xsl:if>
	</xsl:template>
	<xsl:template match="Prop[@Name='SerialNumber']">
		<tr valign="top">
			<td style="white-space:nowrap">
				<span style='font-size:0.6em'>
					<b>Serial Number</b>
				</span>
			</td>
			<td style='white-space:nowrap'>
				<span style='font-size:0.6em'>
					<xsl:value-of disable-output-escaping="yes" select="user:GetSerialNumber(Value)"/>
				</span>
			</td>
		</tr>
	</xsl:template>
	<!-- CHANGE_TOTAL_TIME_FORMAT: Use the following template instead of the "TotalTime" template below to get the time in Hour:Minutes:Seconds format.
	-->
		<xsl:template match="Prop[@Name='TotalTime']">
			<xsl:param name="reportOptions"/>
			<xsl:value-of disable-output-escaping="yes" select="user:GetTotalTimeInHHMMSSFormat(Value)"/>
		</xsl:template>
	<!--
	<xsl:template match="Prop[@Name='TotalTime']">
		<xsl:param name="reportOptions"/>
		<xsl:if test="$reportOptions/Prop[@Name = 'IncludeTimes']/Value = 'True'">
			<tr valign="top">
				<td style="white-space:nowrap">
					<span style='font-size:0.6em'>
						<b>Execution Time</b>
					</span>
				</td>
				<td style='white-space:nowrap'>
					<span style='font-size:0.6em'>
						<xsl:choose>
							<xsl:when test="string-length(Value) &gt; 0">
								<xsl:choose>
									<xsl:when test="$reportOptions/Prop[@Name='UseLocalizedDecimalPoint']/Value = 'True' and $gLocalizedDecimalPoint != '.'">
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
					</span>
				</td>
			</tr>
		</xsl:if>
	</xsl:template>
	-->
	<!-- XSLT Section 2.3: Template to add header to the table that contains the report for a sequence call and call Template to handle 'TEResult'  within it. -->
	<xsl:template match="Prop[@Name='SequenceCall']">
		<xsl:param name="reportOptions"/>
		<xsl:if test="$gEnableResultFiltering = 0 or user:IsTableCreatedForSequence(Prop[@Name = 'ResultList']/Value[@ID]/Prop[@Type = 'TEResult']) = 'true'">
			<xsl:if test="Prop[@Name='ResultList'] and Prop[@HBound != '[]']">
				<br/>
				<xsl:value-of select="user:SetSequenceCallIndentationLevel(user:GetIndentationLevel() + 1)"/>
				<h4>
					<xsl:attribute name="style">margin-left:<xsl:value-of select="user:GetIndentationLevel() * user:GetIndentationWidth()"/>px;</xsl:attribute>
					<span style='font-size:0.6em'>
						Begin Sequence: <xsl:value-of select="Prop[@Name='Sequence']/Value"/><br/><xsl:apply-templates select="Prop[@Name='SequenceFile']"/>
					</span>
				</h4>
				<xsl:value-of select="user:SetSequenceCallIndentationLevel(user:GetIndentationLevel() - 1)"/>
				<xsl:if test="$gEnableResultFiltering = 0 or user:IsTableCreationNecessary(Prop[@Name = 'ResultList']/Value[@ID]/Prop[@Type = 'TEResult']) = 'true'">
					<xsl:value-of select="user:SetSequenceCallIndentationLevel(user:GetIndentationLevel() + 1)"/>
				</xsl:if>
				<xsl:apply-templates select="Prop[@Name='ResultList']/Value[@ID]/Prop[@Type='TEResult']">
					<xsl:with-param name="reportOptions" select="$reportOptions"/>
				</xsl:apply-templates>
				<xsl:if test="$gEnableResultFiltering = 0 or user:IsTableCreatedForSequence(Prop[@Name = 'ResultList']/Value[@ID]/Prop[@Type = 'TEResult']) = 'true'">
					<xsl:if test="user:GetAddTable() = '0'">
						<xsl:value-of disable-output-escaping="yes" select="user:EndTable()"/>
					</xsl:if>
					<xsl:value-of select="user:SetSequenceCallIndentationLevel(user:GetIndentationLevel() - 1)"/>
					<xsl:value-of disable-output-escaping="yes" select="user:ResetBlockLevel()"/>
				</xsl:if>
				<xsl:value-of select="user:SetSequenceCallIndentationLevel(user:GetIndentationLevel() + 1)"/>
				<h4>
					<xsl:attribute name="style">margin-left:<xsl:value-of select="user:GetIndentationLevel() * user:GetIndentationWidth()"/>px;</xsl:attribute>
					<span style='font-size:0.6em'>
						End Sequence: <xsl:value-of select="Prop[@Name='Sequence']/Value"/>
					</span>
				</h4>
				<xsl:value-of select="user:SetSequenceCallIndentationLevel(user:GetIndentationLevel() - 1)"/>
				<br/>
			</xsl:if>
			<xsl:if test="Prop[@Name='ResultList']">
				<xsl:if test="Prop[@Name='ResultList'] and Prop[@HBound = '[]']">
					<br/>
				</xsl:if>
			</xsl:if>
			<!-- In case the resultList is deleted and does not exist in the stream -->
			<xsl:if test="not (Prop[@Name='ResultList'])">
				<br/>
				<xsl:value-of select="user:SetSequenceCallIndentationLevel(user:GetIndentationLevel() + 1)"/>
				<h4>
					<xsl:attribute name="style">margin-left:<xsl:value-of select="user:GetIndentationLevel() * user:GetIndentationWidth()"/>px;</xsl:attribute>
					<span style='font-size:0.6em'>
						Begin Sequence: <xsl:value-of select="Prop[@Name='Sequence']/Value"/><br/><xsl:apply-templates select="Prop[@Name='SequenceFile']"/>
					</span>
				</h4>
				<xsl:value-of select="user:SetSequenceCallIndentationLevel(user:GetIndentationLevel() + 1)"/>
				<h4>
					<xsl:attribute name="style">margin-left:<xsl:value-of select="user:GetIndentationLevel() * user:GetIndentationWidth()"/>px;</xsl:attribute>
					<span style="font-size:0.6em;">
						No Sequence Results Found
					</span>
				</h4>
				<xsl:value-of select="user:SetSequenceCallIndentationLevel(user:GetIndentationLevel() - 1)"/>
				<h4>
					<xsl:attribute name="style">margin-left:<xsl:value-of select="user:GetIndentationLevel() * user:GetIndentationWidth()"/>px;</xsl:attribute>
					<span style='font-size:0.6em'>
						End Sequence: <xsl:value-of select="Prop[@Name='Sequence']/Value"/>
					</span>
				</h4>
				<xsl:value-of select="user:SetSequenceCallIndentationLevel(user:GetIndentationLevel() - 1)"/>
			</xsl:if>
		</xsl:if>
	</xsl:template>
	<!-- XSLT Section 2.4: Template to add sequence file path to the header of the sequence report table -->
	<xsl:template match="Prop[@Name='SequenceFile']">
		<xsl:if test="Value = ''">(<xsl:value-of disable-output-escaping="yes" select="$gUnsavedSeqFileName"/>)</xsl:if>
		<xsl:if test="Value != ''"><xsl:value-of select="Value"/></xsl:if>
	</xsl:template>
	<!--XSLT Section 2.5 Template to add step results into report into the report -->
	<xsl:template match="Value[@ID]/Prop[@Type='TEResult']">
		<xsl:param name="reportOptions"/>
		<xsl:value-of disable-output-escaping="yes" select="user:ProcessCurrentBlockLevel(.)"/>
		<xsl:if test="$gEnableResultFiltering = 0 or user:CheckIfStepSatisfiesFilteringCondition(current()) = 'true'">
			<xsl:if test="Prop[@Name='TS']/Prop[@Name='NumLoops']">
				<xsl:value-of disable-output-escaping="yes" select="user:BeginLoopIndices(.)"/>
			</xsl:if>
			<xsl:if test="Prop[@Name='TS']/Prop[@Name='LoopIndex']">
				<xsl:value-of disable-output-escaping="yes" select="user:TestForStartLoopIndex()"/>
			</xsl:if>
			<xsl:if test="user:GetAddTable() = '1'">
				<xsl:value-of disable-output-escaping="yes" select="user:BeginTable()"/>
			</xsl:if>
			<xsl:variable name="areMeasurementsIncluded" select="$reportOptions/Prop[@Name = 'IncludeMeasurements']/Value"/>
			<xsl:variable name="areLimitsIncluded" select="$reportOptions/Prop[@Name = 'IncludeLimits']/Value"/>
			<xsl:variable name="areAttributesIncluded" select="$reportOptions/Prop[@Name = 'IncludeAttributes']/Value"/>
			<xsl:variable name="stepStatus" select="Prop[@Name='Status']/Value"/>
			<!--  If Status != Skipped adds the other Result Properties -->
			<xsl:if test="$stepStatus != 'Skipped'">
					<!--  If Status != terminated add the other Result Properties -->
					<xsl:if test="$stepStatus != 'Terminated'">
						<xsl:choose>
							<!--- Look for the following properties to find out if it is a Multiple Numeric Limit Step Type 
								1. Step.Result.Measurement
								2. Step.Result.Measurement is an Array of type NI_LimitMeasurement
							-->
							<xsl:when test="Prop[@Name='Measurement'] and Prop/ArrayElementPrototype[@TypeName='NI_LimitMeasurement']">
								<tr>
									<xsl:apply-templates select="Prop[@Name='TS']/Prop[@Name='StepName']"/>
									<xsl:apply-templates select="Prop[@Name='Status']">
										<xsl:with-param name="reportOptions" select="$reportOptions"/>
									</xsl:apply-templates>
									<td colspan="{$gSecondColumnSpan5}">
										<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
									</td>
								</tr>
								<tr valign="middle">
									<td>
										<span style='font-size:0.6em'>
											<xsl:call-template name="GetStdIndentationString"/>Measurement:
										</span>
									</td>
									<td colspan="{$gSecondColumnSpan6}">
										<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
									</td>
								</tr>
								<xsl:if test="$areAttributesIncluded='True' and Prop/Attributes">
									<xsl:variable name="attributePropNodes" select="Prop/Attributes//Prop[@Flags and @Type]"/>
									<xsl:if test="user:CheckIfIncludeInReportIsPresentForAttributes($attributePropNodes, $reportOptions)">
										<tr>
											<td valign="middle" style='white-space:nowrap' colspan='{$gSecondColumnSpan8}'>
												<span style='font-size:0.6em'>
													<xsl:call-template name="GetIndentationString">
														<xsl:with-param name="nLevel" select="2"/>
													</xsl:call-template>Attributes:
												</span>
											</td>
										</tr>
										<xsl:call-template name="PutFlaggedValuesInReport">
											<xsl:with-param name="propNode" select="Prop/Attributes/Prop[@Flags]"/>
											<xsl:with-param name="parentPropName" select="Prop/Attributes"/>
											<xsl:with-param name="bAddPropertyToReport" select="0"/>
											<xsl:with-param name="nLevel" select="3"/>
											<xsl:with-param name="reportOptions" select="$reportOptions"/>
										</xsl:call-template>
									</xsl:if>
								</xsl:if>
								<xsl:apply-templates select="Prop[@Name='Measurement']/Value[@ID]">
									<xsl:with-param name="reportOptions" select="$reportOptions"/>
								</xsl:apply-templates>
							</xsl:when>
							<xsl:otherwise>
								<tr>
									<xsl:apply-templates select="Prop[@Name='TS']/Prop[@Name='StepName']"/>
									<xsl:apply-templates select="Prop[@Name='Status']">
										<xsl:with-param name="reportOptions" select="$reportOptions"/>
									</xsl:apply-templates>
									<!-- Look and for the following properties to find out if it is a Numeric Limit Step Type
									1. Step.Result.Numeric
									2. Step.Comp
									3. Step.Limits
									-->
									<xsl:if test="Prop[@Name='Numeric']">
										<xsl:if test="Prop[@Name='Comp']">
											<xsl:if test="Prop[@Name='Limits']">
												<td align="right">
													<xsl:if test="$areMeasurementsIncluded = 'True'">
														<xsl:if test="(Prop[@Name='Numeric']/Value)">
															<span style='font-size:0.6em;white-space:nowrap'>
																
																	<xsl:choose>
																		<xsl:when test="$reportOptions/Prop[@Name='UseLocalizedDecimalPoint']/Value = 'True' and $gLocalizedDecimalPoint != '.' ">
																			<xsl:value-of select="translate(Prop[@Name='Numeric']/Value, '.', $gLocalizedDecimalPoint)"/>
																		</xsl:when>
																		<xsl:otherwise>
																			<xsl:value-of select="Prop[@Name='Numeric']/Value"/>
																		</xsl:otherwise>
																	</xsl:choose>
																
															</span>
														</xsl:if>
														<xsl:if test="not(Prop[@Name='Numeric']/Value)">
															<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
														</xsl:if>
													</xsl:if>
													<xsl:if test="not($areMeasurementsIncluded = 'True')">
														<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
													</xsl:if>
												</td>
												<td align="left">
													<xsl:if test="not(Prop[@Name='Units']/Value)">
														<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
													</xsl:if>
													<xsl:if test="(Prop[@Name='Units']/Value)">
														<span style='font-size:0.6em'>
															<xsl:call-template name="RemoveWhiteSpaces">
																<xsl:with-param name="inStr" select="Prop[@Name='Units']/Value"/>
															</xsl:call-template>
														</span>
													</xsl:if>
												</td>
												<td align="right">
													<xsl:if test="$areLimitsIncluded = 'True'">
														<xsl:if test="(Prop[@Name='Limits']/Prop[@Name='Low']/Value)">
															<span style='font-size:0.6em;white-space:nowrap'>
																
																	<xsl:choose>
																		<xsl:when test="$reportOptions/Prop[@Name='UseLocalizedDecimalPoint']/Value = 'True' and $gLocalizedDecimalPoint != '.' ">
																			<xsl:value-of select="translate(Prop[@Name='Limits']/Prop[@Name='Low']/Value, '.', $gLocalizedDecimalPoint)"/>
																		</xsl:when>
																		<xsl:otherwise>
																			<xsl:value-of select="Prop[@Name='Limits']/Prop[@Name='Low']/Value"/>
																		</xsl:otherwise>
																	</xsl:choose>
																
															</span>
														</xsl:if>
														<xsl:if test="not(Prop[@Name='Limits']/Prop[@Name='Low']/Value)">
															<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
														</xsl:if>
													</xsl:if>
													<xsl:if test="not($areLimitsIncluded = 'True')">
														<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
													</xsl:if>
												</td>
												<td align="right">
													<xsl:if test="$areLimitsIncluded = 'True'">
														<xsl:if test="(Prop[@Name='Limits']/Prop[@Name='High']/Value)">
															<span style='font-size:0.6em;white-space:nowrap'>
																
																	<xsl:choose>
																		<xsl:when test="$reportOptions/Prop[@Name='UseLocalizedDecimalPoint']/Value = 'True' and $gLocalizedDecimalPoint != '.' ">
																			<xsl:value-of select="translate(Prop[@Name='Limits']/Prop[@Name='High']/Value, '.', $gLocalizedDecimalPoint)"/>
																		</xsl:when>
																		<xsl:otherwise>
																			<xsl:value-of select="Prop[@Name='Limits']/Prop[@Name='High']/Value"/>
																		</xsl:otherwise>
																	</xsl:choose>
																
															</span>
														</xsl:if>
														<xsl:if test="not(Prop[@Name='Limits']/Prop[@Name='High']/Value)">
															<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
														</xsl:if>
													</xsl:if>
													<xsl:if test="not($areLimitsIncluded = 'True')">
														<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
													</xsl:if>
												</td>
												<td align="center">
													<xsl:if test="$areLimitsIncluded != 'True' or not(Prop[@Name='Comp']/Value)">
														<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
													</xsl:if>
													<xsl:if test="($areLimitsIncluded = 'True' and Prop[@Name='Comp']/Value)">
														<span style='font-size:0.6em'>
															<xsl:call-template name="GetComparisonTypeText">
																<xsl:with-param name="compText" select="Prop[@Name='Comp']/Value"/>
															</xsl:call-template>
														</span>
													</xsl:if>
												</td>
												<!-- ADD_COLUMN_DATA_1: Users can add data to the extra column created in CREATE_EXTRA_COLUMNS section here.
												This section adds the data to the column if the step type is a Numeric Limit Test 
												 Ex:To Add StepID information
														<td align="center">
															<span style='font-size:0.6em'>
																<xsl:value-of select="./Prop[@Name='TS']/Prop[@Name='StepId']/Value"/>
															</span>
														</td>
											-->
											</xsl:if>
										</xsl:if>
									</xsl:if>
									<!--- Look for the following properties to find out if it is a String  Value Step Type
									1. Step.Result.String
									2. Step.Comp
									3. Step.Limits.String
									-->
									<xsl:if test="Prop[@Name='String']">
										<xsl:if test="Prop[@Name='Comp']">
											<xsl:if test="Prop[@Name='Limits']">
												<td align="left">
													<xsl:if test="$areMeasurementsIncluded = 'True'">
														<span style='font-size:0.6em'>
															<xsl:if test="Prop[@Name='String']/Value = ''">''</xsl:if>
															<xsl:if test="(Prop[@Name='String']/Value !='')">
																<xsl:call-template name="RemoveWhiteSpaces">
																	<xsl:with-param name="inStr" select="Prop[@Name='String']/Value"/>
																</xsl:call-template>
															</xsl:if>
														</span>
													</xsl:if>
													<xsl:if test="not($areMeasurementsIncluded = 'True')">
														<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
													</xsl:if>
												</td>
												<!-- String Value Tests cannot have units -->
												<td>
													<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
												</td>
												<td align="left">
													<xsl:if test="$areLimitsIncluded = 'True'">
														<span style='font-size:0.6em'>
															<xsl:if test="Prop[@Name='Limits']/Prop[@Name='String']/Value=''">''</xsl:if>
															<xsl:if test="(Prop[@Name='Limits']/Prop[@Name='String']/Value != '')">
																<xsl:call-template name="RemoveWhiteSpaces">
																	<xsl:with-param name="inStr" select="Prop[@Name='Limits']/Prop[@Name='String']/Value"/>
																</xsl:call-template>
															</xsl:if>
														</span>
													</xsl:if>
													<xsl:if test="not($areLimitsIncluded = 'True')">
														<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
													</xsl:if>
												</td>
												<!-- String Value Tests cannot have High Limits -->
												<td>
													<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
												</td>
												<td align="center">
													<xsl:if test="not(Prop[@Name='Comp']/Value) or $areLimitsIncluded != 'True'">
														<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
													</xsl:if>
													<xsl:if test="(Prop[@Name='Comp']/Value) and $areLimitsIncluded = 'True'">
														<span style='font-size:0.6em'>
															<xsl:value-of select="Prop[@Name='Comp']/Value"/>
														</span>
													</xsl:if>
												</td>
												<!-- ADD_COLUMN_DATA_2: Users can add data to the extra column created in CREATE_EXTRA_COLUMNS section here.
												This section adds the data to the column only if the step type is a String Value Test
												 Ex:To Add StepID information 
														<td align="center">
															<span style='font-size:0.6em'>
																<xsl:value-of select="./Prop[@Name='TS']/Prop[@Name='StepId']/Value"/>
															</span>
														</td>
												-->
											</xsl:if>
							</xsl:if>
						</xsl:if>
						<!--- Look for the following properties to find out if it is a Multiple Numeric Limit Step Type 
						1. Step.Result.Measurement
						2. Step.Result.Measurement is an Array of type NI_LimitMeasurement
						  -->
						<xsl:if test="Prop[@Name='Measurement']">
							<xsl:if test="Prop/ArrayElementPrototype[@TypeName='NI_LimitMeasurement']">
								<td colspan="{$gSecondColumnSpan5}">
									<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
								</td>
								<tr valign="middle">
									<td>
										<span style='font-size:0.6em'>
											<xsl:call-template name="GetStdIndentationString"/>Measurement:
										</span>
									</td>
									<td colspan="{$gSecondColumnSpan6}">
										<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
									</td>
								</tr>
								<xsl:if test="$areAttributesIncluded='True' and Prop/Attributes">
									<xsl:variable name="attributePropNodes" select="Prop/Attributes//Prop[@Flags and @Type]"/>
									<xsl:if test="user:CheckIfIncludeInReportIsPresentForAttributes($attributePropNodes, $reportOptions)">
										<tr>
											<td valign="middle" style="white-space:nowrap;" colspan='{$gSecondColumnSpan8}'>
												<span style='font-size:0.6em'>
													<xsl:call-template name="GetIndentationString">
														<xsl:with-param name="nLevel" select="2"/>
													</xsl:call-template>Attributes:
												</span>
											</td>
										</tr>
										<xsl:call-template name="PutFlaggedValuesInReport">
											<xsl:with-param name="propNode" select="Prop/Attributes/Prop[@Flags]"/>
											<xsl:with-param name="parentPropName" select="Prop/Attributes"/>
											<xsl:with-param name="bAddPropertyToReport" select="0"/>
											<xsl:with-param name="nLevel" select="3"/>
											<xsl:with-param name="reportOptions" select="$reportOptions"/>
										</xsl:call-template>
									</xsl:if>
								</xsl:if>
								<xsl:apply-templates select="Prop[@Name='Measurement']/Value[@ID]">
									<xsl:with-param name="reportOptions" select="$reportOptions"/>
								</xsl:apply-templates>
										</xsl:if>
									</xsl:if>
									<!-- All the remaining Step Types -->
									<!--- Look for the following properties to find out if it is a Pass/Fail Test Type
										1. Step.Result.PassFail
									-->
									<xsl:if test="Prop[@Name='PassFail']">
										<td>
											<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
										</td>
										<td>
											<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
										</td>
										<td>
											<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
										</td>
										<td>
											<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
										</td>
										<td>
											<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
										</td>
										<!-- ADD_COLUMN_DATA_3: Users can add data to the extra column created in CREATE_EXTRA_COLUMNS section here.
										This section adds the data to the column only if the step type is a Pass/Fail Test 
												 Ex:To Add StepID information 
												<td align="center">
													<span style='font-size:0.6em'>
														<xsl:value-of select="./Prop[@Name='TS']/Prop[@Name='StepId']/Value"/>
													</span>
												</td>							
										-->
									</xsl:if>
									<!-- handle formatting if is Action Test-->
									<xsl:if test="$stepStatus = 'Done'">
										<xsl:if test="not(Prop[@Name='TS']/Prop[@Name='StepType']/Value = 'SequenceCall')">
											<xsl:if test="not(Prop[@Name = 'PassFail'])">
												<td>
													<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
												</td>
												<td>
													<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
												</td>
												<td>
													<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
												</td>
												<td>
													<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
												</td>
												<td>
													<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
												</td>
												<!-- ADD_COLUMN_DATA_4: Users can add data to the extra column created in CREATE_EXTRA_COLUMNS section here.
												This section adds the data to the column only if the step type is Action and the status is Done
												 Ex:To Add StepID information 
												<td align="center">
													<span style='font-size:0.6em'>
														<xsl:value-of select="./Prop[@Name='TS']/Prop[@Name='StepId']/Value"/>
													</span>
												</td>
												-->
											</xsl:if>
										</xsl:if>
									</xsl:if>
									<xsl:if test="$stepStatus = 'Error'">
										<!-- Make sure that it is not a numeric limit step -->
										<xsl:if test="not(Prop[@Name='Numeric'])">
											<xsl:if test="not(Prop[@Name='Comp'])">
												<xsl:if test="not(Prop[@Name='Limits'])">
													<!-- Make sure that it is not a string value step -->
													<xsl:if test="not(Prop[@Name='String'])">
														<!-- Make sure that it is not a PassFail step -->
														<xsl:if test="not(Prop[@Name='PassFail'])">
															<!-- Make sure that it is not a sequence call step -->
															<xsl:if test="not(Prop[@Name='TS']/Prop[@Name='StepType']/Value = 'SequenceCall')">
																<!-- Make sure that it is not a Multi Numeric limit step -->
																<xsl:if test="not(Prop/ArrayElementPrototype[@TypeName='NI_LimitMeasurement'])">
																	<td>
																		<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
																	</td>
																	<td>
																		<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
																	</td>
																	<td>
																		<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
																	</td>
																	<td>
																		<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
																	</td>
																	<td>
																		<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
																	</td>
																	<!-- ADD_COLUMN_DATA_5: Users can add data to the extra column created in CREATE_EXTRA_COLUMNS section here.
																	This section adds the data to the column only if the status of the step is 'Error' and the step type is
																	not one of the following - Numeric Limit Test, Multi Numeric Limit Test, String Value Test, Pass/Fail Test, Sequence Call
																	Ex:To Add StepID information 
																	<td align="center">
																		<span style='font-size:0.6em'>
																			<xsl:value-of select="./Prop[@Name='TS']/Prop[@Name='StepId']/Value"/>
																		</span>
																	</td>
																	-->
																</xsl:if>
															</xsl:if>
														</xsl:if>
													</xsl:if>
												</xsl:if>
											</xsl:if>
										</xsl:if>
									</xsl:if>
									<!-- Take care of case when status is something else -->
									<xsl:if test="$stepStatus != 'Passed'">
										<xsl:if test="$stepStatus != 'Failed'">
											<xsl:if test="$stepStatus != 'Done'">
												<xsl:if test="$stepStatus != 'Error'">
													<xsl:if test="$stepStatus != 'Running'">
														<!-- Make sure that it is not a numeric limit step -->
														<xsl:if test="not(Prop[@Name='Numeric'])">
															<xsl:if test="not(Prop[@Name='Comp'])">
																<xsl:if test="not(Prop[@Name='Limits'])">
																	<!-- Make sure that it is not a string value step -->
																	<xsl:if test="not(Prop[@Name='String'])">
																		<!-- Make sure that it is not a passFail  step -->
																		<xsl:if test="not(Prop[@Name='PassFail'])">
																			<!-- Make sure that it is not a sequence call step -->
																			<xsl:if test="not(Prop[@Name='TS']/Prop[@Name='StepType']/Value = 'SequenceCall')">
																				<!-- Make sure that it is not a Multi Numeric limit step -->
																				<xsl:if test="not(Prop/ArrayElementPrototype[@TypeName='NI_LimitMeasurement'])">
																					<td>
																						<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
																					</td>
																					<td>
																						<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
																					</td>
																					<td>
																						<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
																					</td>
																					<td>
																						<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
																					</td>
																					<td>
																						<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
																					</td>
																					<!-- ADD_COLUMN_DATA_6: Users can add data to the extra column created in CREATE_EXTRA_COLUMNS section here.
																					This section adds the data to the column only if the status of the step not one of the following
																					Passed, Failed, Error, Done, Running and the step type is
																					not one of the following - Numeric Limit Test, Multi Numeric Limit Test, String Value Test, Pass/Fail Test, Sequence Call
																					Ex:To Add StepID information 
																					<td align="center">
																						<span style='font-size:0.6em'>
																							<xsl:value-of select="./Prop[@Name='TS']/Prop[@Name='StepId']/Value"/>
																						</span>
																					</td>
																					-->
																				</xsl:if>
																			</xsl:if>
																		</xsl:if>
																	</xsl:if>
																</xsl:if>
															</xsl:if>
														</xsl:if>
													</xsl:if>
												</xsl:if>
											</xsl:if>
										</xsl:if>
									</xsl:if>
									<!-- Take care of cases when it is a action step and it is looping-->
									<xsl:if test="$stepStatus = 'Passed'">
										<!-- Make sure that it is not a numeric limit step -->
										<xsl:if test="not(Prop[@Name='Numeric'])">
											<xsl:if test="not(Prop[@Name='Comp'])">
												<xsl:if test="not(Prop[@Name='Limits'])">
													<!-- Make sure that it is not a string value step -->
													<xsl:if test="not(Prop[@Name='String'])">
														<!-- Make sure that it is not a passFail step -->
														<xsl:if test="not(Prop[@Name='PassFail'])">
															<!-- Make sure that it is not a sequence call step -->
															<xsl:if test="not(Prop[@Name='TS']/Prop[@Name='StepType']/Value = 'SequenceCall')">
																<!-- Make sure that it is not a Multi Numeric limit step -->
																<xsl:if test="not(Prop/ArrayElementPrototype[@TypeName='NI_LimitMeasurement'])">
																	<td>
																		<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
																	</td>
																	<td>
																		<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
																	</td>
																	<td>
																		<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
																	</td>
																	<td>
																		<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
																	</td>
																	<td>
																		<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
																	</td>
																	<!-- ADD_COLUMN_DATA_7: Users can add data to the extra column created in CREATE_EXTRA_COLUMNS section here.
																	This section adds the data to the column only if the status of the step is 'Passed' and the step type is
																	not one of the following - Numeric Limit Test, Multi Numeric Limit Test, String Value Test, Pass/Fail Test, Sequence Call
																	Ex:To Add StepID information 
																	<td align="center">
																		<span style='font-size:0.6em'>
																			<xsl:value-of select="./Prop[@Name='TS']/Prop[@Name='StepId']/Value"/>
																		</span>
																	</td>
																	-->
																</xsl:if>
															</xsl:if>
														</xsl:if>
													</xsl:if>
												</xsl:if>
											</xsl:if>
										</xsl:if>
									</xsl:if>
									<!-- Take care of cases when it is a action step and it is looping-->
									<xsl:if test="$stepStatus = 'Failed'">
										<!-- Make sure that it is not a numeric limit step -->
										<xsl:if test="not(Prop[@Name='Numeric'])">
											<xsl:if test="not(Prop[@Name='Comp'])">
												<xsl:if test="not(Prop[@Name='Limits'])">
													<!-- Make sure that it is not a string value step -->
													<xsl:if test="not(Prop[@Name='String'])">
														<!-- Make sure that it is not a PassFail step -->
														<xsl:if test="not(Prop[@Name='PassFail'])">
															<!-- Make sure that it is not a sequence call step -->
															<xsl:if test="not(Prop[@Name='TS']/Prop[@Name='StepType']/Value = 'SequenceCall')">
																<!-- Make sure that it is not a Multi Numeric limit step -->
																<xsl:if test="not(Prop/ArrayElementPrototype[@TypeName='NI_LimitMeasurement'])">
																	<td>
																		<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
																	</td>
																	<td>
																		<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
																	</td>
																	<td>
																		<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
																	</td>
																	<td>
																		<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
																	</td>
																	<td>
																		<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
																	</td>
																	<!-- ADD_COLUMN_DATA_8: Users can add data to the extra column created in CREATE_EXTRA_COLUMNS section here.
																	This section adds the data to the column only if the status of the step is 'Failed' and the step type is
																	not one of the following - Numeric Limit Test, Multi Numeric Limit Test, String Value Test, Pass/Fail Test, Sequence Call
																	Ex:To Add StepID information 
																	<td align="center">
																		<span style='font-size:0.6em'>
																			<xsl:value-of select="./Prop[@Name='TS']/Prop[@Name='StepId']/Value"/>
																		</span>
																	</td>
																	-->
																</xsl:if>
															</xsl:if>
														</xsl:if>
													</xsl:if>
												</xsl:if>
											</xsl:if>
										</xsl:if>
									</xsl:if>
									<!-- Take care of cases when it is a step is running -->
									<xsl:if test="$stepStatus = 'Running'">
										<!-- Make sure that it is not a numeric limit step -->
										<xsl:if test="not(Prop[@Name='Numeric'])">
											<xsl:if test="not(Prop[@Name='Comp'])">
												<xsl:if test="not(Prop[@Name='Limits'])">
													<!-- Make sure that it is not a string value step -->
													<xsl:if test="not(Prop[@Name='String'])">
														<!-- Make sure that it is not a PassFail step -->
														<xsl:if test="not(Prop[@Name='PassFail'])">
															<!-- Make sure that it is not a sequence call step -->
															<xsl:if test="not(Prop[@Name='TS']/Prop[@Name='StepType']/Value = 'SequenceCall')">
																<!-- Make sure that it is not a Multi Numeric limit step -->
																<xsl:if test="not(Prop/ArrayElementPrototype[@TypeName='NI_LimitMeasurement'])">
																	<td>
																		<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
																	</td>
																	<td>
																		<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
																	</td>
																	<td>
																		<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
																	</td>
																	<td>
																		<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
																	</td>
																	<td>
																		<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
																	</td>
																	<!-- ADD_COLUMN_DATA_9: Users can add data to the extra column created in CREATE_EXTRA_COLUMNS section here.
																	This section adds the data to the column only if the status of the step is 'Running' and the step type is
																	not one of the following - Numeric Limit Test, Multi Numeric Limit Test, String Value Test, Pass/Fail Test, Sequence Call
																	Ex:To Add StepID information 
																	<td align="center">
																		<span style='font-size:0.6em'>
																			<xsl:value-of select="./Prop[@Name='TS']/Prop[@Name='StepId']/Value"/>
																		</span>
																	</td>
																	-->
																</xsl:if>
															</xsl:if>
														</xsl:if>
													</xsl:if>
												</xsl:if>
											</xsl:if>
										</xsl:if>
									</xsl:if>
									<!-- Formatting for Sequence Call Steps -->
									<xsl:if test="Prop[@Name='TS']/Prop[@Name='StepType']/Value = 'SequenceCall'">
										<xsl:if test="$gEnableResultFiltering = 0 or user:CheckIfStepSatisfiesFilteringCondition(current()) = 'true'">
											<td>
												<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
											</td>
											<td>
												<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
											</td>
											<td>
												<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
											</td>
											<td>
												<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
											</td>
											<td>
												<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
											</td>
											<!-- ADD_COLUMN_DATA_10: Users can add data to the extra column created in CREATE_EXTRA_COLUMNS section here.
											This section adds the data to the column only if step type is Sequence Call
											Ex:To Add StepID information 
											<td align="center">
												<span style='font-size:0.6em'>
													<xsl:value-of select="./Prop[@Name='TS']/Prop[@Name='StepId']/Value"/>
												</span>
											</td>
											-->
										</xsl:if>
									</xsl:if>
								</tr>
							</xsl:otherwise>
						</xsl:choose>
						<xsl:apply-templates select="Prop[@Name='TS']/Prop[@Name='NumLoops']"/>
						<xsl:apply-templates select="Prop[@Name='TS']/Prop[@Name='NumPassed']"/>
						<xsl:apply-templates select="Prop[@Name='TS']/Prop[@Name='NumFailed']"/>
						<xsl:apply-templates select="Prop[@Name='TS']/Prop[@Name='EndingLoopIndex']">
							<xsl:with-param name="useLocalizedDecimalPoint" select="$reportOptions/Prop[@Name='UseLocalizedDecimalPoint']/Value"/>
						</xsl:apply-templates>
						<xsl:apply-templates select="Prop[@Name='TS']/Prop[@Name='InteractiveExeNum']"/>
						<xsl:apply-templates select="Prop[@Name='TS']/Prop[@Name='Server']"/>
						<xsl:call-template name="PutFlaggedValuesInReport">
							<xsl:with-param name="propNode" select="./Prop[@Flags]"/>
							<xsl:with-param name="parentPropName" select="''"/>
							<xsl:with-param name="bAddPropertyToReport" select="0"/>
							<xsl:with-param name="nLevel" select="1"/>
							<xsl:with-param name="reportOptions" select="$reportOptions"/>
						</xsl:call-template>
						<xsl:if test="$stepStatus = 'Error'">
							<xsl:apply-templates select="Prop[@Name='Error']">
								<xsl:with-param name="reportOptions" select="$reportOptions"/>
							</xsl:apply-templates>
						</xsl:if>
						<xsl:if test="Prop[@Name='ReportText']/Value != ''">
							<xsl:if test="user:IsNotFlowControlStep(.)">
								<xsl:apply-templates select="Prop[@Name='ReportText']">
									<xsl:with-param name="reportOptions" select="$reportOptions"/>
								</xsl:apply-templates>
							</xsl:if>
						</xsl:if>
						<!-- If terminated in sequence call -->
						<!-- If you change this code, duplicate code below -->
						<xsl:if test="Prop[@Name='TS']/Prop[@Name='SequenceCall']/Prop[@Name='ResultList'] and Prop[@Name='TS']/Prop[@Name='SequenceCall']/Prop[@HBound != '[]']">
							<xsl:if test="$gEnableResultFiltering = 0 or user:IsTableCreatedForSequence(Prop[@Name='TS']/Prop[@Name='SequenceCall']/Prop[@Name = 'ResultList']/Value[@ID]/Prop[@Type = 'TEResult']) = 'true'">
								<xsl:if test="user:GetAddTable() = '0'">
									<xsl:value-of disable-output-escaping="yes" select="user:EndTable()"/>
								</xsl:if>
								<xsl:value-of disable-output-escaping="yes" select="user:SetResultLevel(user:GetResultLevel()+1)"/>
								<xsl:value-of select="user:StoreCurrentLoopingLevel()"/>
								<xsl:apply-templates select="Prop[@Name='TS']/Prop[@Name='SequenceCall']">
									<xsl:with-param name="reportOptions" select="$reportOptions"/>
								</xsl:apply-templates>
								<xsl:value-of disable-output-escaping="yes" select="user:ResetBlockLevel()"/>
								<xsl:value-of select="user:RestoreLoopingLevel()"/>
								<xsl:value-of disable-output-escaping="yes" select="user:SetResultLevel(user:GetResultLevel()-1)"/>
								<xsl:value-of select="user:SetAddTable(1)"/>
							</xsl:if>
						</xsl:if>
						<!-- Handle post Action results -->
						<!-- If you change this code, duplicate code below -->
						<xsl:if test="Prop[@Name='TS']/Prop[@Name='PostAction']/Prop[@Name='ResultList'] and Prop[@Name='TS']/Prop[@Name='PostAction']/Prop[@HBound != '[]']">
							<xsl:if test="user:GetAddTable() = '0'">
								<xsl:value-of disable-output-escaping="yes" select="user:EndTable()"/>
							</xsl:if>
							<xsl:value-of disable-output-escaping="yes" select="user:SetResultLevel(user:GetResultLevel()+1)"/>
							<xsl:value-of select="user:StoreCurrentLoopingLevel()"/>
							<xsl:apply-templates select="Prop[@Name='TS']/Prop[@Name='PostAction']">
								<xsl:with-param name="reportOptions" select="$reportOptions"/>
							</xsl:apply-templates>
							<xsl:value-of disable-output-escaping="yes" select="user:ResetBlockLevel()"/>
							<xsl:value-of select="user:RestoreLoopingLevel()"/>
							<xsl:value-of disable-output-escaping="yes" select="user:SetResultLevel(user:GetResultLevel()-1)"/>
							<xsl:value-of select="user:SetAddTable(1)"/>
						</xsl:if>
						<!-- Step status not terminated  -->
				</xsl:if>
				
				<!-- Step status not skipped -->
			</xsl:if>
			<xsl:if test="$stepStatus = 'Skipped'">
				<tr>
					<xsl:apply-templates select="Prop[@Name='TS']/Prop[@Name='StepName']"/>
					<xsl:apply-templates select="Prop[@Name='Status']">
						<xsl:with-param name="reportOptions" select="$reportOptions"/>
					</xsl:apply-templates>
					<td>
						<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
					</td>
					<td>
						<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
					</td>
					<td>
						<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
					</td>
					<td>
						<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
					</td>
					<td>
						<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
					</td>
					<!-- ADD_COLUMN_DATA_11: Users can add data to the extra column created in CREATE_EXTRA_COLUMNS section here.
					This section adds the data to the column only if the status of the step is 'Skipped'
					Ex:To Add StepID information 
					<td align="center">
						<span style='font-size:0.6em'>
							<xsl:value-of select="./Prop[@Name='TS']/Prop[@Name='StepId']/Value"/>
						</span>
					</td>
					-->
				</tr>
			</xsl:if>
			<xsl:if test="$stepStatus = 'Terminated'">
				<tr>
					<xsl:apply-templates select="Prop[@Name='TS']/Prop[@Name='StepName']"/>
					<xsl:apply-templates select="Prop[@Name='Status']">
						<xsl:with-param name="reportOptions" select="$reportOptions"/>
					</xsl:apply-templates>
					<td>
						<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
					</td>
					<td>
						<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
					</td>
					<td>
						<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
					</td>
					<td>
						<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
					</td>
					<td>
						<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
					</td>
					<!-- ADD_COLUMN_DATA_12: Users can add data to the extra column created in CREATE_EXTRA_COLUMNS section here.
					This section adds the data to the column only if the status of the step is 'Terminated'
					Ex:To Add StepID information 
					<td align="center">
						<span style='font-size:0.6em'>
							<xsl:value-of select="./Prop[@Name='TS']/Prop[@Name='StepId']/Value"/>
						</span>
					</td>
					-->
				</tr>
				<!-- If terminated in sequence call -->
				<!-- If you change this code, duplicate code above -->
				<xsl:if test="Prop[@Name='TS']/Prop[@Name='SequenceCall']/Prop[@Name='ResultList'] and Prop[@Name='TS']/Prop[@Name='SequenceCall']/Prop[@HBound != '[]']">
					<xsl:if test="$gEnableResultFiltering = 0 or user:IsTableCreatedForSequence(Prop[@Name='TS']/Prop[@Name='SequenceCall']/Prop[@Name = 'ResultList']/Value[@ID]/Prop[@Type = 'TEResult']) = 'true'">
						<xsl:if test="user:GetAddTable() = '0'">
							<xsl:value-of disable-output-escaping="yes" select="user:EndTable()"/>
						</xsl:if>
						<xsl:value-of disable-output-escaping="yes" select="user:SetResultLevel(user:GetResultLevel()+1)"/>
						<xsl:value-of select="user:StoreCurrentLoopingLevel()"/>
						<xsl:apply-templates select="Prop[@Name='TS']/Prop[@Name='SequenceCall']">
							<xsl:with-param name="reportOptions" select="$reportOptions"/>
						</xsl:apply-templates>
						<xsl:value-of disable-output-escaping="yes" select="user:ResetBlockLevel()"/>
						<xsl:value-of select="user:RestoreLoopingLevel()"/>
						<xsl:value-of disable-output-escaping="yes" select="user:SetResultLevel(user:GetResultLevel()-1)"/>
						<xsl:value-of select="user:SetAddTable(1)"/>
					</xsl:if>
				</xsl:if>
				<!-- Handle post Action results -->
				<!-- If you change this code, duplicate code above -->
				<xsl:if test="Prop[@Name='TS']/Prop[@Name='PostAction']/Prop[@Name='ResultList'] and Prop[@Name='TS']/Prop[@Name='PostAction']/Prop[@HBound != '[]']">
					<xsl:if test="user:GetAddTable() = '0'">
						<xsl:value-of disable-output-escaping="yes" select="user:EndTable()"/>
					</xsl:if>
					<xsl:value-of disable-output-escaping="yes" select="user:SetResultLevel(user:GetResultLevel()+1)"/>
					<xsl:value-of select="user:StoreCurrentLoopingLevel()"/>
					<xsl:apply-templates select="Prop[@Name='TS']/Prop[@Name='PostAction']">
						<xsl:with-param name="reportOptions" select="$reportOptions"/>
					</xsl:apply-templates>
					<xsl:value-of disable-output-escaping="yes" select="user:ResetBlockLevel()"/>
					<xsl:value-of select="user:RestoreLoopingLevel()"/>
					<xsl:value-of disable-output-escaping="yes" select="user:SetResultLevel(user:GetResultLevel()-1)"/>
					<xsl:value-of select="user:SetAddTable(1)"/>
				</xsl:if>
			</xsl:if>
			<xsl:if test="Prop[@Name='TS']/Prop[@Name='LoopIndex']">
				<xsl:value-of disable-output-escaping="yes" select="user:TestForEndLoopIndex()"/>
			</xsl:if>
		</xsl:if>
	</xsl:template>
	<xsl:template match="Prop[@Name='PostAction']">
		<xsl:param name="reportOptions"/>
		<xsl:if test="Prop[@Name='ResultList']">
			<xsl:if test="Prop[@Name='ResultList'] and Prop[@HBound != '[]']">
				<br/>
				<xsl:value-of select="user:SetSequenceCallIndentationLevel(user:GetIndentationLevel() + 1)"/>
				<h4>
					<xsl:attribute name="style">white-space:nowrap;margin-left:<xsl:value-of select="(user:GetIndentationLevel()) * user:GetIndentationWidth()"/>px;</xsl:attribute>
					<span style='font-size:0.6em'>
						Begin Sequence: <xsl:value-of select="Prop[@Name='Sequence']/Value"/><br/><xsl:apply-templates select="Prop[@Name='SequenceFile']"/>
					</span>
				</h4>
				<xsl:value-of disable-output-escaping="yes" select="user:BeginTable()"/>
				<xsl:apply-templates select="Prop[@Name='ResultList']/Value[@ID]/Prop[@Type='TEResult']">
					<xsl:with-param name="reportOptions" select="$reportOptions"/>
				</xsl:apply-templates>
				<xsl:value-of disable-output-escaping="yes" select="user:EndTable()"/>
				<xsl:value-of disable-output-escaping="yes" select="user:ResetBlockLevel()"/>
				<h4>
					<xsl:attribute name="style">margin-left:<xsl:value-of select="(user:GetIndentationLevel()) * user:GetIndentationWidth()"/>px;</xsl:attribute>
					<span style='font-size:0.6em'>
						End Sequence: <xsl:value-of select="Prop[@Name='Sequence']/Value"/>
					</span>
				</h4>
				<xsl:value-of select="user:SetSequenceCallIndentationLevel(user:GetIndentationLevel() - 1)"/>
				<br/>
			</xsl:if>
		</xsl:if>
		<xsl:if test="Prop[@Name='ResultList']">
			<xsl:if test="Prop[@Name='ResultList'] and Prop[@HBound = '[]']">
				<br/>
			</xsl:if>
		</xsl:if>
		<!-- In case the resultList is deleted and does not exist in the stream -->
		<xsl:if test="not (Prop[@Name='ResultList'])">
			<span style='font-size:0.6em'>
				<br/>
				No Post Action Results Found
			</span>
		</xsl:if>
	</xsl:template>
	<!-- XSLT Section 2.6 Template that adds the step name and step execution status to the report table -->
	<xsl:template match="Prop[@Name='StepName']">
		<td>
			<span style='font-size:0.6em'>
				<xsl:variable name="isCriticalFailure">
					<xsl:call-template name="GetIsCriticalFailure">
						<xsl:with-param name="node" select="."/>
					</xsl:call-template>
				</xsl:variable>
				<xsl:choose>
					<xsl:when test="$isCriticalFailure = 'True'">
						<a>
							<xsl:attribute name="name">ResultId<xsl:value-of select="user:GetResultId(.)"/></xsl:attribute>
							<xsl:value-of disable-output-escaping="yes" select="user:GetInitialIndentation(.)"/>
							<!-- Empty step name case -->
							<xsl:if test="Value=''">
								<xsl:call-template name="GetEmptyCellValue"/>
							</xsl:if>
							<xsl:if test="Value != ''">
								<xsl:call-template name="RemoveWhiteSpaces">
									<xsl:with-param name="inStr" select="Value"/>
								</xsl:call-template>
							</xsl:if>
							<xsl:value-of select="user:GetLoopIndex(.)"/>
							<xsl:value-of select="user:GetStepNameAddition(.)"/>
						</a>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of disable-output-escaping="yes" select="user:GetInitialIndentation(.)"/>
						<!-- Empty step name case -->
						<xsl:if test="Value=''">
							<xsl:call-template name="GetEmptyCellValue"/>
						</xsl:if>
						<xsl:if test="Value != ''">
							<xsl:call-template name="RemoveWhiteSpaces">
								<xsl:with-param name="inStr" select="Value"/>
							</xsl:call-template>
						</xsl:if>
						<xsl:value-of select="user:GetLoopIndex(.)"/>
						<xsl:value-of select="user:GetStepNameAddition(.)"/>
					</xsl:otherwise>
				</xsl:choose>
			</span>
		</td>
	</xsl:template>
	<!-- Template that adds the Step execution status with the font color set -->
	<xsl:template match="Prop[@Name='Status']">
		<xsl:param name="reportOptions"/>
		<!-- ADD_IMG_STATUS Add images/colors into to step result row/column based on the step status	here-->
		<td valign="middle" align="center">
			<span style='font-size:0.6em'>
				<xsl:variable name="isCriticalFailure">
					<xsl:call-template name="GetIsCriticalFailureFromStatus">
						<xsl:with-param name="node" select="."/>
					</xsl:call-template>
				</xsl:variable>
				<xsl:choose>
					<xsl:when test="$isCriticalFailure = 'True'">
						<xsl:attribute name="style">font-size:0.6em;color:<xsl:call-template name="GetStatusColor">
								<xsl:with-param name="colors" select="$reportOptions/Prop[@Name = 'Colors']"/>
								<xsl:with-param name="status" select="Value"/>
								</xsl:call-template></xsl:attribute>
								<xsl:choose>
									<xsl:when test="string(Value) != ''">
									<b>
										<xsl:value-of select="Value"/>
									</b>
									</xsl:when>
									<xsl:otherwise>
										<xsl:call-template name="GetEmptyCellValue"/>
									</xsl:otherwise>
								</xsl:choose>
					</xsl:when>
					<xsl:otherwise>
						<xsl:attribute name="style">font-size:0.6em;color:<xsl:call-template name="GetStatusColor">
								<xsl:with-param name="colors" select="$reportOptions/Prop[@Name = 'Colors']"/>
								<xsl:with-param name="status" select="Value"/>
							</xsl:call-template></xsl:attribute>
							<xsl:choose>
								<xsl:when test="string(Value) != ''">
									<xsl:value-of select="Value"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:call-template name="GetEmptyCellValue"/>
								</xsl:otherwise>
							</xsl:choose>
					</xsl:otherwise>
				</xsl:choose>
			</span>
		</td>
	</xsl:template>
	<!-- XSLT Section 2.7 Template to add the measurement array of multi-numeric limit steps to the report -->
	<xsl:template match="Prop[@Name='Measurement']/Value[@ID]">
		<xsl:param name="reportOptions"/>
		<xsl:variable name="areMeasurementsIncluded" select="$reportOptions/Prop[@Name = 'IncludeMeasurements']/Value"/>
		<xsl:variable name="areLimitsIncluded" select="$reportOptions/Prop[@Name = 'IncludeLimits']/Value"/>
		<xsl:variable name="areAttributesIncluded" select="$reportOptions/Prop[@Name = 'IncludeAttributes']/Value"/>
		<!-- If there is no status then assume that you not have an measurement array-->
		<xsl:if test="*/Prop[@Name ='Status']">
			<tr>
				<td>
					<span style='font-size:0.6em'>
						<xsl:call-template name="GetIndentationString">
							<xsl:with-param name="nLevel" select="2"/>
						</xsl:call-template>
						<xsl:value-of select="Prop/@Name"/>
					</span>
				</td>
				<td align="center">
					<span>
						<xsl:if test="*/Prop[@Name ='Status']/Value = '' ">
							<span style='font-size:0.6em'><xsl:call-template name="GetEmptyCellValue"/></span>
						</xsl:if>
						<xsl:if test="*/Prop[@Name ='Status']/Value != ''">
							<xsl:attribute name="style">font-size:0.6em;color:<xsl:call-template name="GetStatusColor">
									<xsl:with-param name="colors" select="$reportOptions/Prop[@Name = 'Colors']"/>
									<xsl:with-param name="status" select="*/Prop[@Name='Status']/Value"/>
								</xsl:call-template></xsl:attribute>
							<xsl:value-of select="*/Prop[@Name='Status']/Value"/>
						</xsl:if>
					</span>
				</td>
				<td align="right" valign="middle">
					<xsl:if test="$areMeasurementsIncluded = 'True'">
						<span style='font-size:0.6em;white-space:nowrap'>
							
								<xsl:choose>
									<xsl:when test="$reportOptions/Prop[@Name='UseLocalizedDecimalPoint']/Value = 'True' and $gLocalizedDecimalPoint != '.' ">
										<xsl:value-of select="translate(*/Prop[@Name='Data']/Value, '.', $gLocalizedDecimalPoint)"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="*/Prop[@Name='Data']/Value"/>
									</xsl:otherwise>
								</xsl:choose>
							
						</span>
					</xsl:if>
					<xsl:if test="not($areMeasurementsIncluded = 'True')">
						<xsl:call-template name="GetEmptyCellValue"/>
					</xsl:if>
				</td>
				<td align="left" valign="middle">
					<xsl:if test="not(*/Prop[@Name='Units']/Value)">
						<xsl:call-template name="GetEmptyCellValue"/>
					</xsl:if>
					<xsl:if test="(*/Prop[@Name='Units']/Value)">
						<span style='font-size:0.6em'>
							<xsl:call-template name="RemoveWhiteSpaces">
								<xsl:with-param name="inStr" select="*/Prop[@Name='Units']/Value"/>
							</xsl:call-template>
						</span>
					</xsl:if>
				</td>
				<td align="right" valign="middle">
					<xsl:if test="$areLimitsIncluded = 'True'">
						<span style='font-size:0.6em;white-space:nowrap'>
							
								<xsl:choose>
									<xsl:when test="$reportOptions/Prop[@Name='UseLocalizedDecimalPoint']/Value = 'True' and $gLocalizedDecimalPoint != '.'">
										<xsl:value-of select="translate(*/Prop[@Name='Limits']/Prop[@Name='Low']/Value, '.', $gLocalizedDecimalPoint)"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="*/Prop[@Name='Limits']/Prop[@Name='Low']/Value"/>
									</xsl:otherwise>
								</xsl:choose>
							
						</span>
						<xsl:if test="not(*/Prop[@Name='Limits']/Prop[@Name='Low']/Value)">
							<xsl:call-template name="GetEmptyCellValue"/>
						</xsl:if>
					</xsl:if>
					<xsl:if test="not($areLimitsIncluded = 'True')">
						<xsl:call-template name="GetEmptyCellValue"/>
					</xsl:if>
				</td>
				<td align="right" valign="middle">
					<xsl:if test="$areLimitsIncluded = 'True'">
						<span style='font-size:0.6em;white-space:nowrap'>
							
								<xsl:choose>
									<xsl:when test="$reportOptions/Prop[@Name='UseLocalizedDecimalPoint']/Value = 'True'  and $gLocalizedDecimalPoint != '.'">
										<xsl:value-of select="translate(*/Prop[@Name='Limits']/Prop[@Name='High']/Value, '.', $gLocalizedDecimalPoint)"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="*/Prop[@Name='Limits']/Prop[@Name='High']/Value"/>
									</xsl:otherwise>
								</xsl:choose>
							
						</span>
						<xsl:if test="not(*/Prop[@Name='Limits']/Prop[@Name='High']/Value)">
							<xsl:call-template name="GetEmptyCellValue"/>
						</xsl:if>
					</xsl:if>
					<xsl:if test="not($areLimitsIncluded = 'True')">
						<xsl:call-template name="GetEmptyCellValue"/>
					</xsl:if>
				</td>
				<td align="center" valign="middle">
					<span style='font-size:0.6em'>
						<xsl:if test="$areLimitsIncluded != 'True' or not(Prop/Prop[@Name='Comp']/Value)">
							<xsl:value-of select="$emptyCellValue" disable-output-escaping="yes"/>
						</xsl:if>
						<xsl:if test="($areLimitsIncluded = 'True' and Prop/Prop[@Name='Comp']/Value)">
							<xsl:call-template name="GetComparisonTypeText">
								<xsl:with-param name="compText" select="Prop/Prop[@Name='Comp']/Value"/>
							</xsl:call-template>
						</xsl:if>
					</span>
				</td>
				<!-- ADD_COLUMN_DATA_13: Users can add data to the extra column created in CREATE_EXTRA_COLUMNS section here.
					This section adds the data to the column only if the step result includes a measurement array.
					 Ex:To Add StepID information 
					<td align="center">
						<span style='font-size:0.6em'>
							<xsl:value-of select="../../Prop[@Name='TS']/Prop[@Name='StepId']/Value"/>
						</span>
					</td>
				 -->
			</tr>
			<xsl:if test="$areAttributesIncluded='True'">
				<xsl:if test="Prop/Attributes">
					<xsl:variable name="attributePropNodes" select="Prop/Attributes//Prop[@Flags and @Type]"/>
					<xsl:if test="user:CheckIfIncludeInReportIsPresentForAttributes($attributePropNodes, $reportOptions)">
						<tr>
							<td valign="middle" style='white-space:nowrap' colspan='{$gSecondColumnSpan8}'>
								<span style='font-size:0.6em'>
									<xsl:call-template name="GetIndentationString">
										<xsl:with-param name="nLevel" select="3"/>
									</xsl:call-template>Attributes:
							</span>
							</td>
						</tr>
						<xsl:call-template name="PutFlaggedValuesInReport">
						<xsl:with-param name="propNode" select="Prop/Attributes/Prop[@Flags]"/>
							<xsl:with-param name="parentPropName" select="Prop/Attributes"/>
							<xsl:with-param name="bAddPropertyToReport" select="0"/>
							<xsl:with-param name="nLevel" select="4"/>
							<xsl:with-param name="reportOptions" select="$reportOptions"/>
						</xsl:call-template>
					</xsl:if>
				</xsl:if>
				<xsl:call-template name="ProcessMeasurementChildAttributes">
					<xsl:with-param name="childNodes" select="./Prop/Prop"/>
					<xsl:with-param name="reportOptions" select="$reportOptions"/>
					<xsl:with-param name="nLevel" select="3"/>
				</xsl:call-template>
			</xsl:if>
		</xsl:if>
	</xsl:template>
	<!-- XSLT Section 2.8 Template that add the error message and report text in the report -->
	<!-- Template that adds the Error Message to the report table-->
	<xsl:template match="Prop[@Name='Error']">
		<xsl:param name="reportOptions"/>
		<tr>
			<td valign="top" style='white-space:nowrap'>
				<span>
					<xsl:attribute name="style">font-size:0.6em;color:<xsl:value-of select="$reportOptions/Prop[@Name = 'Colors']/Prop[@Name = 'Error']/Value" disable-output-escaping="no"/></xsl:attribute>
					<xsl:call-template name="GetStdIndentationString"/>
					Error Message: 
				</span>
			</td>
			<td valign="middle" colspan="{$gSecondColumnSpan6}">
				<span>
					<xsl:attribute name="style">font-size:0.6em;color:<xsl:value-of select="$reportOptions/Prop[@Name = 'Colors']/Prop[@Name = 'Error']/Value" disable-output-escaping="no"/></xsl:attribute>
					<xsl:value-of disable-output-escaping="yes" select="user:RemoveIllegalCharacters(Prop[@Name='Msg'])"/>
					[Error Code: <xsl:value-of select="Prop[@Name='Code']/Value"/>]
				</span>
			</td>
		</tr>
	</xsl:template>
	<!-- Template to add the Report Text to the report -->
	<xsl:template match="Prop[@Name='ReportText']">
		<xsl:param name="reportOptions"/>
		<tr>
			<td valign="top" style='white-space:nowrap'>
				<span>
					<xsl:attribute name="style">font-size:0.6em;color:<xsl:value-of select="$reportOptions/Prop[@Name = 'Colors']/Prop[@Name = 'ReportTextBg']/Value" disable-output-escaping="no"/></xsl:attribute>
					<xsl:call-template name="GetStdIndentationString"/>
					Report Text: 
				</span>
			</td>
			<td colspan="{$gSecondColumnSpan6}">
				<span>
					<xsl:attribute name="style">font-size:0.6em;color:<xsl:value-of select="$reportOptions/Prop[@Name = 'Colors']/Prop[@Name = 'ReportTextBg']/Value" disable-output-escaping="no"/>;</xsl:attribute>
					<xsl:value-of disable-output-escaping="yes" select="user:RemoveIllegalCharacters(.)"/>
				</span>
				<br/>
			</td>
		</tr>
	</xsl:template>
	<!-- XSLT Section 2.9 Templates to add the interactive execution number to the report -->
	<xsl:template match="Prop[@Name='InteractiveExeNum']">
		<tr>
			<td valign="middle" style='white-space:nowrap'>
				<span style='font-size:0.6em'>
					<xsl:call-template name="GetStdIndentationString"/>
					Interactive Execution #: 
				</span>
			</td>
			<td style='white-space:nowrap' colspan="{$gSecondColumnSpan6}">
				<span style='font-size:0.6em'>
					<xsl:value-of select="Value"/>
				</span>
			</td>
		</tr>
	</xsl:template>
	<!-- XSLT Section 2.10 Templates to add Server information to the report -->
	<xsl:template match="Prop[@Name='Server']">
		<tr>
			<td valign="middle">
				<span style='font-size:0.6em'>
					<xsl:call-template name="GetStdIndentationString"/>
				Server:
			  </span>
			</td>
			<td style='white-space:nowrap' colspan="{$gSecondColumnSpan6}">
				<span style='font-size:0.6em'>
					<xsl:value-of select="Value"/>
				</span>
			</td>
		</tr>
	</xsl:template>
	<!-- XSLT Section 2.11 Templates to handle summary information for the loops of particular step in case 'looping' is enabled for the step or the user loops or runs some selected steps only-->
	<xsl:template match="Prop[@Name='NumLoops']">
		<tr>
			<td style='white-space:nowrap'>
				<span style='font-size:0.6em'>
					<xsl:call-template name="GetStdIndentationString"/>
			Number of Loops: 
				</span>
			</td>
			<td style='white-space:nowrap' colspan="{$gSecondColumnSpan6}">
				<span style='font-size:0.6em'>
					<xsl:value-of select="Value"/>
				</span>
			</td>
		</tr>
	</xsl:template>
	<xsl:template match="Prop[@Name='NumPassed']">
		<tr>
			<td style='white-space:nowrap'>
				<span style='font-size:0.6em'>
					<xsl:call-template name="GetStdIndentationString"/>
					Number of Passes: 
				</span>
			</td>
			<td style='white-space:nowrap' colspan="{$gSecondColumnSpan6}">
				<span style='font-size:0.6em'>
					<xsl:value-of select="Value"/>
				</span>
			</td>
		</tr>
	</xsl:template>
	<xsl:template match="Prop[@Name='NumFailed']">
		<tr>
			<td style='white-space:nowrap'>
				<span style='font-size:0.6em'>
					<xsl:call-template name="GetStdIndentationString"/>
					Number of Failures: 
			</span>
			</td>
			<td style='white-space:nowrap' colspan="{$gSecondColumnSpan6}">
				<span style='font-size:0.6em'>
					<xsl:value-of select="Value"/>
				</span>
			</td>
		</tr>
	</xsl:template>
	<xsl:template match="Prop[@Name='EndingLoopIndex']">
		<xsl:param name="useLocalizedDecimalPoint"/>
		<tr>
			<td style='white-space:nowrap'>
				<span style='font-size:0.6em'>
					<xsl:call-template name="GetStdIndentationString"/>
					Final Loop Index:
			  </span>
			</td>
			<td style='white-space:nowrap' colspan="{$gSecondColumnSpan6}">
				<span style='font-size:0.6em'>
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
		<xsl:if test="Value">
			<tbody>
				<tr>
					<td align="center">
						<span style='font-size:0.6em'>
							<b>Step</b>
						</span>
					</td>
					<td align="center">
						<span style='font-size:0.6em'>
							<b>Sequence</b>
						</span>
					</td>
					<td align="center">
						<span style='font-size:0.6em'>
							<b>Sequence File</b>
						</span>
					</td>
				</tr>
				<xsl:for-each select="Value">
					<xsl:sort select="@ID" order="descending"/>
					<tr>
						<td>
							<span style='font-size:0.6em'>
								<a>
									<xsl:attribute name="href">#ResultId<xsl:value-of select="Prop/Prop[@Name='ResultId']/Value"/></xsl:attribute>
									<xsl:value-of select="Prop/Prop[@Name='StepName']/Value"/>
								</a>
							</span>
						</td>
						<td>
							<span style='font-size:0.6em'>
								<xsl:value-of select="Prop/Prop[@Name='SequenceName']/Value"/>
							</span>
						</td>
						<td>
							<span style='font-size:0.6em'>
								<xsl:choose>
									<xsl:when test="Prop/Prop[@Name='SequenceFileName']/Value != ''">
										<xsl:value-of select="Prop/Prop[@Name='SequenceFileName']/Value"/>
									</xsl:when>
									<xsl:otherwise><xsl:value-of disable-output-escaping="yes" select="$gUnsavedSeqFileName"/></xsl:otherwise>
								</xsl:choose>
							</span>
						</td>
					</tr>
				</xsl:for-each>
			</tbody>
		</xsl:if>
	</xsl:template>
	<!-- XSLT Section 3  Templates to process Batch report-->
	<!-- XSLT Section 3.1 Template to process the batch header table and call the template to build the batch report table-->
	<xsl:template match="Report[@Type='Batch']">
		<xsl:variable name="reportOptions" select="Prop[@Name='ReportOptions']"/>
		<xsl:value-of select="user:InitFlagGlobalVariables(Prop[@Name='ReportOptions'])"/>
		<h3>
			<span style='font-size:0.7em'>
				<xsl:value-of select="@Title"/>
			</span>
		</h3>
		<table border="1" cellpadding="2" cellspacing="0" width="60%">
			<xsl:apply-templates select="Prop[@Name='StationInfo']/Prop[@Name='StationID']"/>
			<tr valign="top">
				<td style="white-space:nowrap">
					<span style='font-size:0.6em'>
						<b>Batch Serial Number</b>
					</span>
				</td>
				<td style='white-space:nowrap'>
					<span style='font-size:0.6em'>
						<xsl:value-of disable-output-escaping="yes" select="user:GetSerialNumberFromText(string(@BatchSerialNumber))"/>
					</span>
				</td>
			</tr>
			<xsl:apply-templates select="Prop[@Name='StartDate']"/>
			<xsl:apply-templates select="Prop[@Name='StartTime']"/>
			<xsl:apply-templates select="Prop[@Name='StationInfo']/Prop[@Name='LoginName']"/>
			<xsl:apply-templates select="Prop[@Name='TSRData']/Prop[@Name='TSRFileName']"/>
			<xsl:apply-templates select="Prop[@Name='TSRData']/Prop[@Name='TSRFileID']"/>
			<xsl:apply-templates select="Prop[@Name='TSRData']/Prop[@Name='TSRFileClosed']"/>
		</table>
		<br/>
		<xsl:apply-templates select="BatchTable">
			<xsl:with-param name="reportOptions" select="$reportOptions"/>
		</xsl:apply-templates>
		<h3>
			<span style='font-size:0.7em'>
				End Batch Report
			</span>
		</h3>
		<hr/>
	</xsl:template>
	<!-- XSLT Section 3.2 Template to build the Batch report table-->
	<xsl:template match="BatchTable">
		<xsl:param name="reportOptions"/>
		<table border="1" cellpadding="2" cellspacing="0" width="60%">
			<tr valign="top">
				<td align="center" style="width:10%;white-space:nowrap">
					<span style='font-size:0.6em'>
						<b>Test Socket</b>
					</span>
				</td>
				<td align="center" style="width:25%;white-space:nowrap">
					<span style='font-size:0.6em'>
						<b>UUT Serial Number</b>
					</span>
				</td>
				<td align="center" style="width:25%;white-space:nowrap">
					<span style='font-size:0.6em'>
						<b>UUT Result</b>
					</span>
				</td>
			</tr>
			<xsl:apply-templates select="UUThref">
				<xsl:with-param name="reportOptions" select="$reportOptions"/>
			</xsl:apply-templates>
		</table>
	</xsl:template>
	<!-- XSLT Section 3.3 Template to add data into the Batch report table -->
	<xsl:template match="UUThref">
		<xsl:param name="reportOptions"/>
		<tr align="center">
			<td>
				<span style='font-size:0.6em'>
				<xsl:choose>
					<xsl:when test="string(@SocketIndex) != ''">
						<xsl:value-of select="@SocketIndex"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:call-template name="GetEmptyCellValue"/>
					</xsl:otherwise>
				</xsl:choose>
				</span>
			</td>
			<td>
				<span style='font-size:0.6em'>
					<a>
						<xsl:if test="@Anchor != ''">
							<xsl:attribute name="href"><xsl:value-of select="user:GetLinkURL(.)"/>#<xsl:value-of select="@Anchor"/></xsl:attribute>
						</xsl:if>
						<xsl:choose>
							<xsl:when test="string-length(normalize-space(@LinkName)) = 0">NONE</xsl:when>
							<xsl:otherwise><xsl:value-of select="@LinkName"/></xsl:otherwise>
						</xsl:choose>	
					</a>
				</span>
			</td>
			<td>
				<span>
					<xsl:attribute name="style">font-size:0.6em;color:<xsl:call-template name="GetStatusColor">
							<xsl:with-param name="colors" select="$reportOptions/Prop[@Name = 'Colors']"/>
							<xsl:with-param name="status" select="@UUTResult"/>
						</xsl:call-template></xsl:attribute>
						<xsl:choose>
							<xsl:when test="string(@UUTResult) != ''">
								<xsl:value-of select="@UUTResult"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:call-template name="GetEmptyCellValue"/>
							</xsl:otherwise>
						</xsl:choose>
					
				</span>
			</td>
		</tr>
	</xsl:template>
	<!-- XSLT Section 4  Templates common to both UUT and Batch report	-->
	<!-- XSLT Section 4.1  Template to add stationID and Login Name to the report -->
	<!-- Template to add the StationID to the report-->
	<xsl:template match="Prop[@Name='StationID']">
		<tr valign="top">
			<td style="white-space:nowrap">
				<span style='font-size:0.6em'>
					<b>Station ID</b>
				</span>
			</td>
			<td style='white-space:nowrap'>
				<span style='font-size:0.6em'>
					<xsl:value-of select="Value"/>
				</span>
			</td>
		</tr>
	</xsl:template>
	<!-- Template to add Login Name to the report-->
	<xsl:template match="Prop[@Name='LoginName']">
		<tr valign="top">
			<td style="white-space:nowrap">
				<span style='font-size:0.6em'>
					<b>Operator</b>
				</span>
			</td>
			<td style='white-space:nowrap'>
				<span style='font-size:0.6em'>
					<xsl:choose>
						<xsl:when test="string-length(Value) &gt; 0">
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
	<!-- XSLT Section 4.2  Template to add the Start Date and Start Time of the report -->
	<!-- Template to add Start Date to the report-->
	<xsl:template match="Prop[@Name='StartDate']">
		<tr valign="top">
			<td style="white-space:nowrap">
				<span style='font-size:0.6em'>
					<b>Date</b>
				</span>
			</td>
			<td style='white-space:nowrap'>
				<span style='font-size:0.6em'>
					<xsl:value-of select="Prop[@Name='Text']/Value"/>
				</span>
			</td>
		</tr>
	</xsl:template>
	<!-- Template to add Start Time of the report -->
	<xsl:template match="Prop[@Name='StartTime']">
		<tr valign="top">
			<td style="white-space:nowrap">
				<span style='font-size:0.6em'>
					<b>Time</b>
				</span>
			</td>
			<td style='white-space:nowrap'>
				<span style='font-size:0.6em'>
					<xsl:value-of select="Prop[@Name='Text']/Value"/>
				</span>
			</td>
		</tr>
	</xsl:template>
	<!-- XSLT Section 5 Templates to insert all flagged information into the report table along with addtional results.-->
	<!-- XSLT Section 5.1 Templates to get empty cell values, standard indentation and comparison text-->
	<xsl:template name="GetEmptyCellValue">
		<xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text>
	</xsl:template>
	<!-- Template to get the standard indentation.-->
	<xsl:template name="GetStdIndentationString">
		<xsl:text disable-output-escaping="yes">&amp;nbsp;&amp;nbsp;</xsl:text>
	</xsl:template>
	<!-- Template to get the comparison type based on the comparison text.-->
	<xsl:template name="GetComparisonTypeText">
		<xsl:param name="compText"/>
		<xsl:value-of select="$compText"/>
		<xsl:choose>
			<xsl:when test="$compText='EQ'">
				<xsl:text disable-output-escaping="yes">(==)</xsl:text>
			</xsl:when>
			<xsl:when test="$compText='NE'">
				<xsl:text disable-output-escaping="yes">(!=)</xsl:text>
			</xsl:when>
			<xsl:when test="$compText='GT'">
				<xsl:text disable-output-escaping="yes">(&gt;)</xsl:text>
			</xsl:when>
			<xsl:when test="$compText='GE'">
				<xsl:text disable-output-escaping="yes">(&gt;=)</xsl:text>
			</xsl:when>
			<xsl:when test="$compText='LT'">
				<xsl:text disable-output-escaping="yes">(&lt;)</xsl:text>
			</xsl:when>
			<xsl:when test="$compText='LE'">
				<xsl:text disable-output-escaping="yes">(&lt;=)</xsl:text>
			</xsl:when>
			<xsl:when test="$compText='GTLT'">
				<xsl:text disable-output-escaping="yes">(&gt; &lt;)</xsl:text>
			</xsl:when>
			<xsl:when test="$compText='GELT'">
				<xsl:text disable-output-escaping="yes">(&gt;= &lt;)</xsl:text>
			</xsl:when>
			<xsl:when test="$compText='GELE'">
				<xsl:text disable-output-escaping="yes">(&gt;= &lt;=)</xsl:text>
			</xsl:when>
			<xsl:when test="$compText='GTLE'">
				<xsl:text disable-output-escaping="yes">(&gt; &lt;=)</xsl:text>
			</xsl:when>
			<xsl:when test="$compText='LTGT'">
				<xsl:text disable-output-escaping="yes">&lt; &gt;</xsl:text>
			</xsl:when>
			<xsl:when test="$compText='LTGE'">
				<xsl:text disable-output-escaping="yes">&lt; &gt;=</xsl:text>
			</xsl:when>
			<xsl:when test="$compText='LEGE'">
				<xsl:text disable-output-escaping="yes">&lt;= &gt;=</xsl:text>
			</xsl:when>
			<xsl:when test="$compText='LEGT'">
				<xsl:text disable-output-escaping="yes">&lt;= &gt;</xsl:text>
			</xsl:when>
			<xsl:when test="$compText='LOG'"/>
			<xsl:when test="string-length($compText) = 0">
				<xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
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
	<!-- XSLT Section 5.3 - None -->
	<!-- XSLT Section 5.4 Template to put flagged values in report.-->
	<xsl:template name="PutFlaggedValuesInReport">
		<xsl:param name="propNode"/>
		<xsl:param name="parentPropName"/>
		<xsl:param name="bAddPropertyToReport"/>
		<xsl:param name="nLevel"/>
		<xsl:param name="reportOptions"/>
		<xsl:param name="flattenedStructure" select="false()"/>
		<xsl:param name="objectPath"/>
		<xsl:for-each select="$propNode">
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
				<xsl:with-param name="parentPropName" select="$parentPropName"/>
				<xsl:with-param name="bAddPropertyToReport" select="$bAddPropertyToReport"/>
				<xsl:with-param name="nLevel" select="$nLevel"/>
				<xsl:with-param name="reportOptions" select="$reportOptions"/>
				<xsl:with-param name="flattenedStructure" select="$flattenedStructure"/>
				<xsl:with-param name="objectPath" select="$objectPath"/>
			</xsl:call-template>
		</xsl:for-each>
	</xsl:template>
	<!-- XSLT Section 5.5 Template to add values into report if the flag to include it in the report is set.-->
	<xsl:template name="AddIfFlagSet">
		<xsl:param name="propNode"/>
		<xsl:param name="propLabel"/>
		<xsl:param name="parentPropName"/>
		<xsl:param name="bAddPropertyToReport"/>
		<xsl:param name="nLevel"/>
		<xsl:param name="reportOptions"/>
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
							<xsl:when test="$propNode/@Type = 'Array'">
								<xsl:variable name="arrayElemPropTypeName">
									<xsl:if test="$propNode/@Name = 'Measurement'">
										<xsl:value-of select="$propNode/ArrayElementPrototype/@TypeName"/>
									</xsl:if>
									<xsl:if test="$propNode/@Name != 'Measurement'">
										""
									</xsl:if>
								</xsl:variable>
								
								<xsl:if test="$arrayElemPropTypeName != 'NI_LimitMeasurement'">
									<xsl:variable name="numDimensions">
										<xsl:call-template name="GetArrayDimensions">
											<xsl:with-param name="dimensionString" select="$propNode/@LBound"/>
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
										<!-- Call AddArrayToReportAsGraph only if the array elements are numeric type and the number of dimensions is less than or equal to 2 and 
										IncludeArrayMeasurement report option is set to Insert Graph and the graph control is installed and if representation is not UInt64 and I64-->
										<xsl:when test="($numDimensions - 1) &lt;= 2 and $propNode/@ElementType = 'Number' and $includeArrayMeasurement = 2 
											and $gGraphControlInstalled = 1  and $propNodeRepresentation = 'DBL' and $isDecimal='true' and count($propNode/Value)>0">
											<xsl:value-of select="user:AddArrayToReportAsGraph($propNode, $propNode/@Name, string($propLabel), $nLevel, boolean($flattenedStructure), string($currentObjPath))" disable-output-escaping="yes"/>
											<xsl:if test="$gIncludeAttributes='True'">
												<xsl:call-template name="AddAttributesToReport">
													<xsl:with-param name="reportOptions" select="$reportOptions"/>
													<xsl:with-param name="nLevel" select="$nLevel"/>
													<xsl:with-param name="flattenedStructure" select="$flattenedStructure"/>
													<xsl:with-param name="objectPath" select="$currentObjPath"/>
												</xsl:call-template>
											</xsl:if>
										</xsl:when>
										<!-- For all other cases the array will be added as a table -->
										<xsl:otherwise>
										     <xsl:call-template name="AddArrayToReportAsTable">
												<xsl:with-param name="propNode" select="$propNode"/>
												<xsl:with-param name="propName" select="$propNode/@Name"/>
												<xsl:with-param name="propLabel" select="$propLabel"/>
												<xsl:with-param name="nLevel" select="$nLevel"/>
												<xsl:with-param name="reportOptions" select="$reportOptions"/>
												<xsl:with-param name="flattenedStructure" select="$flattenedStructure"/>
												<xsl:with-param name="objectPath" select="$currentObjPath"/>
											</xsl:call-template>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:if>
								
								
							</xsl:when>
							<xsl:otherwise>
								<xsl:choose>
									<xsl:when test="./Value">
										<!-- In case the property is a leaf node add it as line to the report. Localize the decimal point if it is a number and the report option UseLocalizedDecimalPoint is set to true.-->
										<xsl:choose>
											<xsl:when test="($propNode/@Name = 'String' and $propNode/@Type = 'String' and $parentPropType = 'TEResult' and $propNode/../Prop[@Name='Comp' and @Type='String'] and $propNode/../Prop[@Name='Limits' and @Type='Obj']) or 
												($propNode/@Name = 'Numeric' and $parentPropType = 'TEResult' and $propNode/@Type = 'Number' and $propNode/../Prop[@Name='Comp' and @Type='String'] and $propNode/../Prop[@Name='Limits' and @Type='Obj']) or
												($propNode/@Name = 'PassFail' and $parentPropName = 'TEResult' and $propNode/@Type = 'Boolean') or
												($propNode/@Name = 'Comp' and $parentPropType = 'TEResult' and $propNode/@Type = 'String' and $propNode/../Prop[@Name='Limits' and @Type='Obj']) or
												($propNode/@Name = 'Units' and $parentPropType = 'TEResult' and $propNode/@Type = 'String' and $propNode/../Prop[@Name='Comp' and @Type='String'] and $propNode/../Prop[@Name='Limits' and @Type='Obj'])">
												<xsl:if test="$gIncludeAttributes='True'">
													<xsl:if test="./Attributes">
														<xsl:variable name="attributePropNodes" select="./Attributes//Prop[@Flags and @Type]"/>
														<xsl:if test="user:CheckIfIncludeInReportIsPresentForAttributes($attributePropNodes, $reportOptions)">
															<tr>
																<td valign="middle" style='white-space:nowrap' colspan='{$gSecondColumnSpan8}'>
																	<span style='font-size:0.6em'>
																		<xsl:call-template name="GetIndentationString">
																			<xsl:with-param name="nLevel" select="$nLevel"/>
																		</xsl:call-template>
																		<xsl:choose>
																			<xsl:when test="$propNode/@Name='Comp'">Comparison Type:</xsl:when>
																			<xsl:otherwise><xsl:value-of select="$propLabel"/>:</xsl:otherwise>
																		</xsl:choose>
																	</span>
																</td>
															</tr>
															<tr>
																<td valign="middle" style='white-space:nowrap' colspan='{$gSecondColumnSpan8}'>
																	<span style='font-size:0.6em'>
																		<xsl:call-template name="GetIndentationString">
																			<xsl:with-param name="nLevel" select="$nLevel + 1"/>
																		</xsl:call-template>Attributes:
																	</span>
																</td>
															</tr>
															<xsl:call-template name="PutFlaggedValuesInReport">
																<xsl:with-param name="propNode" select="./Attributes/Prop[@Flags]"/>
																<xsl:with-param name="parentPropName" select="./Attributes"/>
																<xsl:with-param name="bAddPropertyToReport" select="0"/>
																<xsl:with-param name="nLevel" select="$nLevel + 2"/>
																<xsl:with-param name="reportOptions" select="$reportOptions"/>
															</xsl:call-template>
														</xsl:if>
													</xsl:if>
												</xsl:if>
											</xsl:when>
											<xsl:when test="($propNode/@Name = 'String' and $parentPropName = 'Limits' and $propNode/@Type = 'String') or
												($propNode/@Name = 'Low' and $parentPropName = 'Limits' and $propNode/@Type = 'Number') or
												($propNode/@Name = 'High' and $parentPropName = 'Limits' and $propNode/@Type = 'Number') ">
												<xsl:if test="$gIncludeAttributes='True'">
													<xsl:if test="./Attributes">
														<xsl:variable name="attributePropNodes" select="./Attributes//Prop[@Flags and @Type]"/>
														<xsl:if test="user:CheckIfIncludeInReportIsPresentForAttributes($attributePropNodes, $reportOptions)">
															<xsl:if test="not($propNode/../Attributes)">
																<tr>
																	<td valign="middle" style='white-space:nowrap' colspan='{$gSecondColumnSpan8}'>
																		<span style='font-size:0.6em'>
																			<xsl:call-template name="GetIndentationString">
																				<xsl:with-param name="nLevel" select="$nLevel - 1"/>
																			</xsl:call-template>Limits:
																		</span>
																	</td>
																</tr>
															</xsl:if>
															<tr>
																<td valign="middle" style='white-space:nowrap' colspan='{$gSecondColumnSpan8}'>
																	<span style='font-size:0.6em'>
																		<xsl:call-template name="GetIndentationString">
																			<xsl:with-param name="nLevel" select="$nLevel"/>
																		</xsl:call-template><xsl:value-of select="$propLabel"/>:
																	</span>
																</td>
															</tr>
															<tr>
																<td valign="middle" style='white-space:nowrap' colspan='{$gSecondColumnSpan8}'>
																	<span style='font-size:0.6em'>
																		<xsl:call-template name="GetIndentationString">
																			<xsl:with-param name="nLevel" select="$nLevel + 1"/>
																		</xsl:call-template>Attributes:
																	</span>
																</td>
															</tr>
															<xsl:call-template name="PutFlaggedValuesInReport">
																<xsl:with-param name="propNode" select="./Attributes/Prop[@Flags]"/>
																<xsl:with-param name="parentPropName" select="./Attributes"/>
																<xsl:with-param name="bAddPropertyToReport" select="0"/>
																<xsl:with-param name="nLevel" select="$nLevel + 2"/>
																<xsl:with-param name="reportOptions" select="$reportOptions"/>
															</xsl:call-template>
														</xsl:if>
													</xsl:if>
												</xsl:if>
											</xsl:when>
											<xsl:otherwise>
												<xsl:choose>
													<xsl:when test="$propNode/@Type = 'Number' ">
														<xsl:variable name="localizedValue">
															<xsl:choose>
																<xsl:when test="$reportOptions/Prop[@Name='UseLocalizedDecimalPoint']/Value = 'True'  and $gLocalizedDecimalPoint != '.'">
																	<xsl:value-of select="translate($propNode/Value, '.', $gLocalizedDecimalPoint)"/>
																</xsl:when>
																<xsl:otherwise>
																	<xsl:value-of select="$propNode/Value"/>
																</xsl:otherwise>
															</xsl:choose>
														</xsl:variable>
														<xsl:call-template name="GetResultLine">
															<xsl:with-param name="name" select="$propNode/@Name"/>
															<xsl:with-param name="value" select="$localizedValue"/>
															<xsl:with-param name="parentNode" select="$propLabel"/>
															<xsl:with-param name="nLevel" select="$nLevel"/>
															<xsl:with-param name="propNode" select="$propNode"/>
															<xsl:with-param name="flattenedStructure" select="$flattenedStructure"/>
															<xsl:with-param name="objectPath" select="$currentObjPath"/>
														</xsl:call-template>
													</xsl:when>
													<xsl:otherwise>
														<xsl:call-template name="GetResultLine">
															<xsl:with-param name="name" select="$propNode/@Name"/>
															<xsl:with-param name="value" select="$propNode/Value"/>
															<xsl:with-param name="parentNode" select="$propLabel"/>
															<xsl:with-param name="nLevel" select="$nLevel"/>
															<xsl:with-param name="propNode" select="$propNode"/>
															<xsl:with-param name="flattenedStructure" select="$flattenedStructure"/>
															<xsl:with-param name="objectPath" select="$currentObjPath"/>
														</xsl:call-template>
													</xsl:otherwise>
												</xsl:choose>
												<xsl:if test="$gIncludeAttributes='True'">
													<xsl:call-template name="AddAttributesToReport">
														<xsl:with-param name="reportOptions" select="$reportOptions"/>
														<xsl:with-param name="nLevel" select="$nLevel"/>
														<xsl:with-param name="flattenedStructure" select="$flattenedStructure"/>
														<xsl:with-param name="objectPath" select="$currentObjPath"/>
													</xsl:call-template>
												</xsl:if>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:when>
									<xsl:otherwise>
										<!--in case the property is a container with at least 1 child property with the Flags attribute add the property and call PutFlaggedValuesInReport passing the child elements-->
										<xsl:if test="count($propNode/Prop[@Flags]) > 0">
											<xsl:choose>
												<xsl:when test="$propNode/@TypeName = 'NI_TDMSReference'">
													<xsl:call-template name="PutTDMSReference">
														<xsl:with-param name="propNode" select="$propNode"/>
														<xsl:with-param name="bAddPropertyToReport" select="1"/>
														<xsl:with-param name="nLevel" select="$nLevel"/>
														<xsl:with-param name="reportOptions" select="$reportOptions"/>
														<xsl:with-param name="propLabel" select="$propLabel"/>
														<xsl:with-param name="flattenedStructure" select="$flattenedStructure"/>
														<xsl:with-param name="objectPath" select="$currentObjPath"/>
													</xsl:call-template>
												</xsl:when>
												<xsl:otherwise>
													<xsl:if test="$propLabel != 'Limits' and $flattenedStructure=false()">
														<tr>
															<td style='white-space:nowrap' colspan='{$gSecondColumnSpan8}'>
																<span style='font-size:0.6em'>
																	<xsl:call-template name="GetIndentationString">
																		<xsl:with-param name="nLevel" select="$nLevel"/>
																	</xsl:call-template>
																	<xsl:value-of select="$propLabel"/>:
																</span>
															</td>
														</tr>
														<xsl:call-template name="AddAttributesToReport">
															<xsl:with-param name="reportOptions" select="$reportOptions"/>
															<xsl:with-param name="nLevel" select="$nLevel"/>
															<xsl:with-param name="flattenedStructure" select="$flattenedStructure"/>
															<xsl:with-param name="objectPath" select="$currentObjPath"/>
														</xsl:call-template>
													</xsl:if>
													<xsl:call-template name="PutFlaggedValuesInReport">
														<xsl:with-param name="propNode" select="$propNode/Prop[@Flags]"/>
														<xsl:with-param name="parentPropName" select="$propNode/@Name"/>
														<xsl:with-param name="bAddPropertyToReport" select="1"/>
														<xsl:with-param name="nLevel" select="$nLevel +1"/>
														<xsl:with-param name="reportOptions" select="$reportOptions"/>
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
							<xsl:when test="$propNode/@Type = 'Array'">
								<xsl:variable name="arrayElemPropTypeName">
									<xsl:choose>
										<xsl:when test="$propNode/@Name = 'Measurement'">
											<xsl:value-of select="$propNode/*[0]/@TypeName"/>
										</xsl:when>
										<xsl:otherwise>""</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								<xsl:if test="$arrayElemPropTypeName != 'NI_LimitMeasurement'">
									<!-- For arrays of Objects, call PutFlaggedValuesInReport for each of the child properties-->
									<xsl:if test="$propNode/@ElementType = 'Obj'">
										<xsl:variable name="addLabel" select="$gIncludeAttributes='True' and $flattenedStructure=false() and ($nLevel != 1 or ($propNode/@Name!='AdditionalResults' and $propNode/@Name!='Parameters' )) and user:CheckIfIncludeInReportIsPresentForAttributes($propNode//Prop[@Flags and @Type], $reportOptions)"/>
										<xsl:if test="$addLabel">
											<tr>
												<td valign="middle" style='white-space:nowrap' colspan='{$gSecondColumnSpan8}'>
													<span style='font-size:0.6em'>
														<xsl:call-template name="GetIndentationString">
															<xsl:with-param name="nLevel" select="$nLevel"/>
														</xsl:call-template><xsl:value-of select="$propLabel"/>:
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
											<xsl:call-template name="PutFlaggedValuesInReport">
												<xsl:with-param name="propNode" select="Prop[@Flags]"/>
												<xsl:with-param name="parentPropName" select="concat($propLabel,@ID)"/>
												<xsl:with-param name="bAddPropertyToReport" select="0"/>
												<xsl:with-param name="nLevel" select="number($nextLevel)"/>
												<xsl:with-param name="reportOptions" select="$reportOptions"/>
												<xsl:with-param name="flattenedStructure" select="$flattenedStructure"/>
												<xsl:with-param name="objectPath" select="$currentObjPath"/>
											</xsl:call-template>
										</xsl:for-each>
									</xsl:if>
								</xsl:if>
							</xsl:when>
							<xsl:otherwise>
								<xsl:if test="count($propNode/Prop[@Flags and @Type]) &gt; 0">
									<xsl:if test="$gIncludeAttributes='True'">
										<xsl:if test="$flattenedStructure=false() and user:CheckIfIncludeInReportIsPresentForAttributes($propNode//Prop[@Flags and @Type], $reportOptions)">
											<tr>
												<td valign="middle" style='white-space:nowrap' colspan='{$gSecondColumnSpan8}'>
													<span style='font-size:0.6em'>
														<xsl:call-template name="GetIndentationString">
															<xsl:with-param name="nLevel" select="$nLevel"/>
														</xsl:call-template><xsl:value-of select="$propLabel"/>:
													</span>
												</td>
											</tr>
										</xsl:if>
									</xsl:if>
									<xsl:call-template name="PutFlaggedValuesInReport">
										<xsl:with-param name="propNode" select="$propNode/Prop[@Flags]"/>
										<xsl:with-param name="parentPropName" select="$propNode/@Name"/>
										<xsl:with-param name="bAddPropertyToReport" select="0"/>
										<xsl:with-param name="nLevel" select="$nLevel + 1"/>
										<xsl:with-param name="reportOptions" select="$reportOptions"/>
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
	<!--Template to add attributes, if present, for the flagged value being added to the report-->
	<xsl:template name="AddAttributesToReport">
		<xsl:param name="reportOptions"/>
		<xsl:param name="nLevel"/>
		<xsl:param name="flattenedStructure" select="false()"/>
		<xsl:param name="objectPath"/>
		<xsl:if test="./Attributes">
			<xsl:variable name="attributePropNodes" select="./Attributes//Prop[@Flags and @Type]"/>
			<xsl:if test="user:CheckIfIncludeInReportIsPresentForAttributes($attributePropNodes, $reportOptions)">
			<xsl:if test="$flattenedStructure = false()">
					<tr>
						<td valign="middle" style='white-space:nowrap' colspan='{$gSecondColumnSpan8}'>
							<span style='font-size:0.6em'>
								<xsl:call-template name="GetIndentationString">
									<xsl:with-param name="nLevel" select="$nLevel + 1"/>
								</xsl:call-template>Attributes:
							</span>
						</td>
					</tr>
				</xsl:if>
				<xsl:call-template name="PutFlaggedValuesInReport">
					<xsl:with-param name="propNode" select="./Attributes/Prop[@Flags]"/>
					<xsl:with-param name="parentPropName" select="./Attributes"/>
					<xsl:with-param name="bAddPropertyToReport" select="0"/>
					<xsl:with-param name="nLevel" select="$nLevel + 2"/>
					<xsl:with-param name="reportOptions" select="$reportOptions"/>
					<xsl:with-param name="flattenedStructure" select="$flattenedStructure"/>
					<xsl:with-param name="objectPath" select="concat($objectPath, '.Attributes')"/>
				</xsl:call-template>
			</xsl:if>
		</xsl:if>
	</xsl:template>
	<!--To add measurement children attributes -->
	<xsl:template name="ProcessMeasurementChildAttributes">
		<xsl:param name="reportOptions"/>
		<xsl:param name="childNodes"/>
		<xsl:param name="nLevel"/>
		<xsl:for-each select="$childNodes">
			<xsl:choose>
				<xsl:when test="@Name='Limits'">
					<xsl:if test="./Attributes">
					<xsl:if test="user:CheckIfIncludeInReportIsPresentForAttributes(./Attributes//Prop[@Flags and @Type], $reportOptions)">
							<tr>
								<td valign="middle" style='white-space:nowrap' colspan='{$gSecondColumnSpan8}'>
									<span style='font-size:0.6em'>
										<xsl:call-template name="GetIndentationString">
											<xsl:with-param name="nLevel" select="$nLevel"/>
										</xsl:call-template>Limits:
									</span>
								</td>
							</tr>
							<tr>
								<td valign="middle" style='white-space:nowrap' colspan='{$gSecondColumnSpan8}'>
									<span style='font-size:0.6em'>
										<xsl:call-template name="GetIndentationString">
											<xsl:with-param name="nLevel" select="$nLevel + 1"/>
										</xsl:call-template>Attributes:
									</span>
								</td>
							</tr>
							<xsl:call-template name="PutFlaggedValuesInReport">
								<xsl:with-param name="propNode" select="./Attributes/Prop[@Flags]"/>
								<xsl:with-param name="parentPropName" select="./Attributes"/>
								<xsl:with-param name="bAddPropertyToReport" select="0"/>
								<xsl:with-param name="nLevel" select="$nLevel + 2"/>
								<xsl:with-param name="reportOptions" select="$reportOptions"/>
							</xsl:call-template>
						</xsl:if>
					</xsl:if>
							
					<xsl:for-each select="./Prop[@Flags]">
						<xsl:if test="./Attributes">
					<xsl:if test="user:CheckIfIncludeInReportIsPresentForAttributes(./Attributes//Prop[@Flags and @Type], $reportOptions)">
								<tr>
									<td valign="middle" style='white-space:nowrap' colspan='{$gSecondColumnSpan8}'>
										<span style='font-size:0.6em'>
											<xsl:call-template name="GetIndentationString">
												<xsl:with-param name="nLevel" select="$nLevel"/>
											</xsl:call-template>Limits.<xsl:value-of select="@Name"/>:
									</span>
									</td>
								</tr>
								<tr>
									<td valign="middle" style='white-space:nowrap' colspan='{$gSecondColumnSpan8}'>
										<span style='font-size:0.6em'>
											<xsl:call-template name="GetIndentationString">
												<xsl:with-param name="nLevel" select="$nLevel + 1"/>
											</xsl:call-template>Attributes:
									</span>
									</td>
								</tr>
								<xsl:call-template name="PutFlaggedValuesInReport">
								<xsl:with-param name="propNode" select="./Attributes/Prop[@Flags]"/>
									<xsl:with-param name="parentPropName" select="./Attributes"/>
									<xsl:with-param name="bAddPropertyToReport" select="0"/>
									<xsl:with-param name="nLevel" select="$nLevel + 2"/>
									<xsl:with-param name="reportOptions" select="$reportOptions"/>
								</xsl:call-template>
							</xsl:if>
						</xsl:if>
					</xsl:for-each>
			
					
				</xsl:when>
				<xsl:otherwise>
					<xsl:if test="./Attributes">
						<xsl:variable name="attributePropNodes" select="./Attributes//Prop[@Flags and @Type]"/>
						<xsl:if test="user:CheckIfIncludeInReportIsPresentForAttributes($attributePropNodes, $reportOptions)">
							<tr>
								<td valign="middle" style='white-space:nowrap' colspan='{$gSecondColumnSpan8}'>
									<span style='font-size:0.6em'>
										<xsl:call-template name="GetIndentationString">
											<xsl:with-param name="nLevel" select="$nLevel"/>
										</xsl:call-template>
										<xsl:choose>
											<xsl:when test="@Name='Comp'">Comparison Type:</xsl:when>
											<xsl:otherwise><xsl:value-of select="@Name"/>:</xsl:otherwise>
										</xsl:choose>
									</span>
								</td>
							</tr>
							<tr>
								<td valign="middle" style='white-space:nowrap' colspan='{$gSecondColumnSpan8}'>
									<span style='font-size:0.6em'>
										<xsl:call-template name="GetIndentationString">
											<xsl:with-param name="nLevel" select="$nLevel + 1"/>
										</xsl:call-template>Attributes:
									</span>
								</td>
							</tr>
							<xsl:call-template name="PutFlaggedValuesInReport">
								<xsl:with-param name="propNode" select="./Attributes/Prop[@Flags]"/>
								<xsl:with-param name="parentPropName" select="./Attributes"/>
								<xsl:with-param name="bAddPropertyToReport" select="0"/>
								<xsl:with-param name="nLevel" select="$nLevel + 2"/>
								<xsl:with-param name="reportOptions" select="$reportOptions"/>
							</xsl:call-template>
						</xsl:if>
					</xsl:if>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>
	<!-- Template to add instances of NI_TDMSReference type-->
	<xsl:template name="PutTDMSReference">
		<xsl:param name="propNode"/>
		<xsl:param name="bAddPropertyToReport"/>
		<xsl:param name="nLevel"/>
		<xsl:param name="reportOptions"/>
		<xsl:param name="propLabel"/>
		<xsl:param name="flattenedStructure" select="false()"/>
		<xsl:param name="objectPath"/>
		<xsl:variable name="includeAttributes" select="$reportOptions/Prop[@Name = 'IncludeAttributes']/Value"/>
		<!-- Except File, if all sub-properties is empty, then NI_TDMSReference should be displayed in single line -->
		<xsl:variable name="shouldCreateContainerIfStringLengthGreaterThanZero">
			<xsl:for-each select="$propNode/Prop[@Name!='File']">
				<xsl:value-of select="./Value"/>
			</xsl:for-each>
		</xsl:variable>
		<xsl:if test="string-length($shouldCreateContainerIfStringLengthGreaterThanZero) > 0">
			<!-- Create a row for the container name and process attributes of the container -->
			<xsl:if test="$flattenedStructure = false()">
				<tr>
					<td style='white-space:nowrap' colspan='{$gSecondColumnSpan7}'>
						<span style='font-size:0.6em'>
							<xsl:call-template name="GetIndentationString">
								<xsl:with-param name="nLevel" select="$nLevel"/>
							</xsl:call-template>
							<xsl:value-of select="$propLabel"/>:
						</span>
					</td>
				</tr>
			</xsl:if>
			<xsl:if test="$includeAttributes='True'">
				<xsl:call-template name="AddAttributesToReport">
					<xsl:with-param name="reportOptions" select="$reportOptions"/>
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
		<xsl:choose>
			<xsl:when test="$flattenedStructure = false()">
				<tr>
					<td valign='middle' style='white-space:nowrap'>
						<span style='font-size:0.6em'>
							<xsl:call-template name="GetIndentationString">
								<xsl:with-param name="nLevel" select="$filePathVariableLevel"/>
							</xsl:call-template>
							<!-- If being displayed in single line, use the name of the container, else use the name of sub-property -->
							<xsl:choose>
								<xsl:when test="string-length($shouldCreateContainerIfStringLengthGreaterThanZero) > 0">File:</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="$propLabel"/>:
								</xsl:otherwise>
							</xsl:choose>
						</span>
					</td>
					<td valign='middle' style='white-space:nowrap' colspan='{$gSecondColumnSpan6}'>
						<xsl:choose>
							<!-- Create an hyperlink if TestStand.Hyperlink attribute is true. Otherwise treat it like a string variable -->
							<xsl:when test="$propNode/Prop[@Name='File']/Value != '' and $propNode/Prop[@Name='File']/Attributes/Prop[@Name='TestStand']/Prop[@Name='Hyperlink' and @Type='Boolean']/Value='True'">
								<a>
									<xsl:attribute name="href"><xsl:value-of select="$propNode/Prop[@Name='File']/Value"/></xsl:attribute>
									<span style='font-size:0.6em'>
										<xsl:call-template name="RemoveWhiteSpaces">
											<xsl:with-param name="inStr" select="$propNode/Prop[@Name='File']/Value"/>
										</xsl:call-template>
									</span>
								</a>
							</xsl:when>
							<xsl:otherwise>
								<span style='font-size:0.6em'>
									<xsl:call-template name="RemoveWhiteSpaces">
										<xsl:with-param name="inStr" select="$propNode/Prop[@Name='File']/Value"/>
									</xsl:call-template>
								</span>
							</xsl:otherwise>
						</xsl:choose>
					</td>
				</tr>
			</xsl:when>
			<xsl:otherwise>
				<tr valign="top">
					<td style="white-space:nowrap">
						<span style='font-size:0.6em'>
							<b>
								<xsl:choose>
									<xsl:when test="string-length($shouldCreateContainerIfStringLengthGreaterThanZero) > 0"><xsl:value-of select="$objectPath"/>.File:</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="$objectPath"/>: 
									</xsl:otherwise>
								</xsl:choose>
							</b>
						</span>
					</td>
					<td style="white-space:nowrap">
						<span style='font-size:0.6em'>
							<xsl:choose>
								<!-- Create an hyperlink if TestStand.Hyperlink attribute is true. Otherwise treat it like a string variable -->
								<xsl:when test="$propNode/Prop[@Name='File']/Value != '' and $propNode/Prop[@Name='File']/Attributes/Prop[@Name='TestStand']/Prop[@Name='Hyperlink' and @Type='Boolean']/Value='True'">
									<a>
										<xsl:attribute name="href"><xsl:value-of select="$propNode/Prop[@Name='File']/Value"/></xsl:attribute>
										<xsl:call-template name="RemoveWhiteSpaces">
											<xsl:with-param name="inStr" select="$propNode/Prop[@Name='File']/Value"/>
										</xsl:call-template>
									</a>
								</xsl:when>
								<xsl:otherwise>
									<xsl:call-template name="RemoveWhiteSpaces">
										<xsl:with-param name="inStr" select="$propNode/Prop[@Name='File']/Value"/>
									</xsl:call-template>
								</xsl:otherwise>
							</xsl:choose>
						</span>
					</td>
				</tr>
			</xsl:otherwise>
		</xsl:choose>
		<!-- Process attributes for the File property if NI_TDMSReference is displayed in multiple line or process attributes of container-->
		<xsl:if test="$includeAttributes='True'">
			<xsl:choose>
				<xsl:when test="string-length($shouldCreateContainerIfStringLengthGreaterThanZero) > 0">
					<xsl:for-each select="$propNode/Prop[@Name='File']">
						<xsl:call-template name="AddAttributesToReport">
							<xsl:with-param name="reportOptions" select="$reportOptions"/>
							<xsl:with-param name="nLevel" select="$filePathVariableLevel"/>
							<xsl:with-param name="flattenedStructure" select="$flattenedStructure"/>
							<xsl:with-param name="objectPath" select="concat($objectPath, '.', @Name)"/>
						</xsl:call-template>
					</xsl:for-each>
				</xsl:when>
				<xsl:otherwise>
					<xsl:call-template name="AddAttributesToReport">
						<xsl:with-param name="reportOptions" select="$reportOptions"/>
						<xsl:with-param name="nLevel" select="$filePathVariableLevel"/>
						<xsl:with-param name="flattenedStructure" select="$flattenedStructure"/>
						<xsl:with-param name="objectPath" select="$objectPath"/>
					</xsl:call-template>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
		<!-- If NI_TDMSReference is displayed in multiple lines, then display non-empty sub-properties and process its attributes -->
		<xsl:if test="string-length($shouldCreateContainerIfStringLengthGreaterThanZero) > 0">
			<xsl:for-each select="$propNode/Prop[@Name!='File']">
				<xsl:if test="./Value!=''">
					<xsl:call-template name="GetResultLine">
						<xsl:with-param name="name" select="@Name"/>
						<xsl:with-param name="value" select="./Value"/>
						<xsl:with-param name="parentNode" select="../@Name"/>
						<xsl:with-param name="nLevel" select="$nLevel + 1"/>
						<xsl:with-param name="propNode" select="."/>
						<xsl:with-param name="flattenedStructure" select="$flattenedStructure"/>
						<xsl:with-param name="objectPath" select="concat($objectPath, '.', @Name)"/>
					</xsl:call-template>
					<xsl:if test="$includeAttributes='True'">
						<xsl:call-template name="AddAttributesToReport">
							<xsl:with-param name="reportOptions" select="$reportOptions"/>
							<xsl:with-param name="nLevel" select="$nLevel + 1"/>
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
		<xsl:param name="propNode"/>
		<xsl:param name="flattenedStructure" select="false()"/>
		<xsl:param name="objectPath"/>
		<xsl:variable name="shouldCreateHyperlink">
			<xsl:choose>
				<xsl:when test="$value != '' and $propNode/@Type = 'String' and $propNode/@TypeName = 'Path' and $propNode/Attributes/Prop[@Name='TestStand']/Prop[@Name='Hyperlink' and @Type='Boolean']/Value = 'True'">True</xsl:when>
				<xsl:otherwise>False</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$flattenedStructure = false()">
				<!-- Set propLabel variable to name parameter if the name is not empty otherwise set it to the parentName parameter-->
				<xsl:variable name="propLabel">
					<xsl:choose>
						<xsl:when test="$name != '' ">
							<xsl:value-of select="$name"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="$parentNode"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<tr>
					<td valign='middle' style='white-space:nowrap'>
						<span style='font-size:0.6em'>
							<xsl:call-template name="GetIndentationString">
								<xsl:with-param name="nLevel" select="$nLevel"/>
							</xsl:call-template>
							<xsl:value-of select="$propLabel"/>:
						</span>
					</td>
					<td valign='middle' style='white-space:nowrap' colspan='{$gSecondColumnSpan6}'>
						<span style='font-size:0.6em'>
							<a>
								<xsl:if test="$shouldCreateHyperlink = 'True'">
									<xsl:attribute name="href">
										<xsl:value-of select="$value"/>
									</xsl:attribute>
								</xsl:if>
								<xsl:call-template name="RemoveWhiteSpaces">
									<xsl:with-param name="inStr" select="$value"/>
								</xsl:call-template>
							</a>
						</span>
					</td>
				</tr>
			</xsl:when>
			<xsl:otherwise>
				<tr valign="top">
					<td style="white-space:nowrap">
						<span style='font-size:0.6em'>
							<b>
								 <xsl:value-of select="$objectPath"/>: 
							</b>
						</span>
					</td>
					<td style="white-space:nowrap">
						<span style='font-size:0.6em'>
							<a>
								<xsl:if test="$shouldCreateHyperlink = 'True'">
									<xsl:attribute name="href">
										<xsl:value-of select="$value"/>
									</xsl:attribute>
								</xsl:if>
								<xsl:call-template name="RemoveWhiteSpaces">
									<xsl:with-param name="inStr" select="$value"/>
								</xsl:call-template>
							</a>
						</span>
					</td>
				</tr>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- XSLT Section 5.7 Template to get the indentation based on the level.-->
	<xsl:template name="GetIndentationString">
		<xsl:param name="nLevel"/>
		<xsl:choose>
			<xsl:when test="$nLevel &gt; 0">
				<xsl:call-template name="GetStdIndentationString"/>
				<xsl:call-template name="GetIndentationString">
					<xsl:with-param name="nLevel" select="$nLevel - 1"/>
				</xsl:call-template>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	<!-- XSLT Section 5.8 Template to insert Array to the report.-->
	<xsl:template name="AddArrayToReportAsTable">
		<xsl:param name="propNode"/>
		<xsl:param name="propName"/>
		<xsl:param name="propLabel"/>
		<xsl:param name="nLevel"/>
		<xsl:param name="reportOptions"/>
		<xsl:param name="flattenedStructure" select="false()"/>
		<xsl:param name="objectPath"/>
		<xsl:variable name="valueNodes" select="./Value"/>
		<xsl:variable name="elementType" select="@ElementType"/>
		<xsl:variable name="includeAttributes" select="$reportOptions/Prop[@Name = 'IncludeAttributes']/Value"/>
		<xsl:variable name="arrayMeasurementFilter" select="user:ConvertToDecimalValue(string($reportOptions/Prop[@Name = 'ArrayMeasurementFilter']/Value))"/>
		<xsl:variable name="arrayMeasurementMax" select="user:ConvertToDecimalValue(string($reportOptions/Prop[@Name = 'ArrayMeasurementMax']/Value))"/>
		<xsl:variable name="numberOfNodes" select="count($valueNodes)"/>
		<xsl:variable name="bAddArray">
			<xsl:choose>
				<!-- Set bAddArray to False if ArrayMeasurementFilter is set to Exclude if larger than max and array size is greater than the max elements specified in the report options-->
				<xsl:when test="($arrayMeasurementFilter = 2 and $numberOfNodes > $arrayMeasurementMax)">False</xsl:when>
				<xsl:otherwise>True</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="nMax">
			<!--variable nMax holds the number of elements that need to be added to the report-->
			<xsl:choose>
				<xsl:when test="$arrayMeasurementFilter = 1">
					<!--If ArrayMeasurementFilter is set to Include upto Max-->
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
						<tr>
							<td valign="top">
								<span style='font-size:0.6em'>
									<xsl:variable name="arraySizeString">
										<xsl:choose>
											<xsl:when test="$numberOfNodes &gt; 0">
												<!--Get the dimesion string for non empty arrays-->
												<xsl:call-template name="GetArraySizeString">
													<xsl:with-param name="lowerBound" select="@LBound"/>
													<xsl:with-param name="upperBound" select="@HBound"/>
												</xsl:call-template>:
											</xsl:when>
											<xsl:otherwise>[0..empty]:</xsl:otherwise>
										</xsl:choose>
									</xsl:variable>
									<xsl:choose>
										<xsl:when test="$flattenedStructure = false()">
											<xsl:call-template name="GetIndentationString">
												<xsl:with-param name="nLevel" select="$nLevel"/>
											</xsl:call-template>
											<xsl:value-of select="$propLabel"/><xsl:value-of select="$arraySizeString"/>
										</xsl:when>
										<xsl:otherwise>
											<b><xsl:value-of select="$objectPath" disable-output-escaping="no"/>
												<xsl:value-of select="$arraySizeString" disable-output-escaping="no"/>:</b>
										</xsl:otherwise>
									</xsl:choose>
								</span>
							</td>
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
								<xsl:with-param name="flattenedStructure" select="$flattenedStructure"/>
							</xsl:call-template>
						</tr>
						<xsl:if test="$includeAttributes='True'">
							<xsl:call-template name="AddAttributesToReport">
								<xsl:with-param name="reportOptions" select="$reportOptions"/>
								<xsl:with-param name="nLevel" select="$nLevel"/>
								<xsl:with-param name="flattenedStructure" select="$flattenedStructure"/>
								<xsl:with-param name="objectPath" select="$objectPath"/>
							</xsl:call-template>
						</xsl:if>
					</xsl:if>
				</xsl:if>
			</xsl:when>
			<!--Handle String or Boolean arrays-->
			<xsl:when test="$elementType = 'String' or $elementType = 'Boolean'">
				<xsl:if test="$includeArrayMeasurements = 'True'">
					<xsl:if test="$bAddArray = 'True'">
						<tr>
							<td valign="top">
								<span style='font-size:0.6em'>
									<xsl:call-template name="GetIndentationString">
										<xsl:with-param name="nLevel" select="$nLevel"/>
									</xsl:call-template>
									<xsl:variable name="arraySizeString">
										<xsl:choose>
											<xsl:when test="$numberOfNodes &gt; 0">
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
											<xsl:value-of select="$propLabel"/>
											<xsl:value-of select="$arraySizeString"/>:
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="$objectPath"/>
											<xsl:value-of select="$arraySizeString"/>:
										</xsl:otherwise>
									</xsl:choose>
								</span>
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
								<xsl:with-param name="flattenedStructure" select="$flattenedStructure"/>
							</xsl:call-template>
						</tr>
						<xsl:if test="$includeAttributes='True'">
							<xsl:call-template name="AddAttributesToReport">
								<xsl:with-param name="reportOptions" select="$reportOptions"/>
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
						<td colspan='{$gSecondColumnSpan7}'>
							<span style='font-size:0.6em'>
								<xsl:call-template name="GetIndentationString">
									<xsl:with-param name="nLevel" select="$nLevel"/>
								</xsl:call-template>
								<xsl:value-of select="$propLabel"/>:
							</span>
						</td>
					</tr>
				</xsl:if>
				<xsl:if test="$includeAttributes='True'">
					<xsl:call-template name="AddAttributesToReport">
						<xsl:with-param name="reportOptions" select="$reportOptions"/>
						<xsl:with-param name="nLevel" select="$nLevel"/>
						<xsl:with-param name="flattenedStructure" select="$flattenedStructure"/>
						<xsl:with-param name="objectPath" select="$objectPath"/>
					</xsl:call-template>
				</xsl:if>
				<!--For all other types add the array and call PutFlaggedValuesInReportForArrayElements-->
				<xsl:for-each select="./Value">
					<xsl:variable name="valueName" select="concat($propLabel, @ID)"/>
					<xsl:call-template name="PutFlaggedValuesInReportForArrayElements">
						<xsl:with-param name="propNodes" select="Prop[@Flags]"/>
						<xsl:with-param name="parentPropName" select="$valueName"/>
						<xsl:with-param name="bAddPropertyToReport" select="1"/>
						<xsl:with-param name="nLevel" select="$nLevel + 1"/>
						<xsl:with-param name="reportOptions" select="$reportOptions"/>
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
		<xsl:param name="flattenedStructure" select="false()"/>
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
			<td>
				<xsl:if test="$flattenedStructure = false()">
					<xsl:attribute name="colspan"><xsl:value-of select="$gSecondColumnSpan6"/></xsl:attribute>
				</xsl:if>
				<span style='font-size:0.6em'>
					<xsl:choose>
						<xsl:when test="count($valueNodes) &gt; 0">
							<xsl:for-each select="$valueNodes">
								<xsl:if test="(position() - 1) mod $inc = 0 and floor((position()-1) div $inc) &lt; $nMax">
									<xsl:value-of select="@ID"/> = '<xsl:choose>
										<xsl:when test="$useLocalizedDecimalPoint = 'True'  and $gLocalizedDecimalPoint != '.'">
											<xsl:value-of select="translate(., '.', $gLocalizedDecimalPoint)"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="."/>
										</xsl:otherwise>
									</xsl:choose>'
									<br/>
								</xsl:if>
							</xsl:for-each>
						</xsl:when>
						<xsl:otherwise>
							<xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text>
						</xsl:otherwise>
					</xsl:choose>
				</span>
			</td>
		</xsl:if>
	</xsl:template>
	<!-- Template to put flagged values in report for array elements.-->
	<xsl:template name="PutFlaggedValuesInReportForArrayElements">
		<xsl:param name="propNodes"/>
		<xsl:param name="parentPropName"/>
		<xsl:param name="bAddPropertyToReport"/>
		<xsl:param name="nLevel"/>
		<xsl:param name="reportOptions"/>
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
				<xsl:with-param name="parentPropName" select="$parentPropName"/>
				<xsl:with-param name="bAddPropertyToReport" select="$bAddPropertyToReport"/>
				<xsl:with-param name="nLevel" select="$nLevel"/>
				<xsl:with-param name="reportOptions" select="$reportOptions"/>
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
	<!-- Template to get array size string.-->
	<xsl:template name="GetArraySizeString">
		<xsl:param name="lowerBound"/>
		<xsl:param name="upperBound"/>
		<!-- Build the arraysize string by recursively parsing the lowerBound and upperBound strings-->
		<xsl:if test="$lowerBound != '' and $upperBound != ''">
			<xsl:variable name="lowerBoundVal" select="substring-before($lowerBound, ']')"/>
			<xsl:variable name="upperBoundVal" select="substring-before($upperBound, ']')"/>
			<xsl:text>[</xsl:text><xsl:value-of select="substring($lowerBoundVal, 2)"/>..<xsl:value-of select="substring($upperBoundVal, 2)"/><xsl:text>]</xsl:text>
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
	<!-- XSLT Section 5.11: None-->
	<!-- XSLT Section 5.12 Template to remove white spaces from a string.-->
	<xsl:template name="RemoveWhiteSpaces">
		<xsl:param name="inStr"/>
		<xsl:variable name="normalizedString" select="normalize-space($inStr)"/>
		<xsl:choose>
			<xsl:when test="string-length($normalizedString) &gt; 0 and substring($normalizedString, 1, 1) = ' '">
				<xsl:call-template name="RemoveWhiteSpaces">
					<xsl:with-param name="inStr" select="$normalizedString"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="string-length($normalizedString) = 0">''</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$normalizedString"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- XSLT Section 5.13 Template to return if the step failure caused the sequence to fail from the Step status property.-->
	<xsl:template name="GetIsCriticalFailureFromStatus">
		<xsl:param name="node"/>
		<xsl:variable name="sfcsfNode" select="$node/../Prop[@Name = 'TS']/Prop[@Name = 'StepCausedSequenceFailure']"/>
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
</xsl:stylesheet>
