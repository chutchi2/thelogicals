import xml.etree.ElementTree as ET
import xlwt
import xlsxwriter

from datetime import datetime
tree = ET.parse('Saturn[1234].xml')
root = tree.getroot()

wb = xlsxwriter.Workbook(datetime.now().strftime("%Y_%m_%d_%H_%M_%S")+'conversions.xls')
ws = wb.add_worksheet()
	
value = root.findall('.//Value')
#for index,child in enumerate(root.findall('.//Value'),start=0):
#	ws.write(index,0,child.text)
#	print (child.attrib)
#	if child.get('ID') is not None:
#		print (child.get('ID'))
count = 0
for Value in root.findall('.//Value'):
	if Value.get('ID') is not None:
		for Prop in root.findall('.//Prop'):
			if Prop.get('Name') == 'Status':
				for Value in Prop:
					if Value is not None:
						#count = count + 1
						ws.write(count,1,Value.text)
						#print(Value.text)
			elif Prop.get('Name') == 'Numeric':
				for Value in Prop:
					if Value is not None:
						#count = count + 1
						ws.write(count,0,Value.text)
						#print(Value.text)
			elif Prop.get('Name') == 'TS':
				print(Prop.get('Name'))
				for Prop in Prop:
					if Prop is not None:
						if Prop.get('Name') == 'StepName':
							print(Prop.get('Name'))


wb.close()
	
