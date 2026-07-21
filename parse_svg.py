import xml.etree.ElementTree as ET
import re

tree = ET.parse('chowdeck.com.svg')
root = tree.getroot()
ns = {'svg': 'http://www.w3.org/2000/svg'}

def get_style_or_attr(node, attr):
    if attr in node.attrib:
        return node.attrib[attr]
    style = node.attrib.get('style', '')
    match = re.search(f"{attr}:\s*([^;]+)", style)
    if match: return match.group(1)
    return None

elements = []

for elem in root.iter():
    tag = elem.tag.split('}')[-1]
    
    if tag == 'text':
        text = "".join(elem.itertext()).strip()
        if text:
            y = float(elem.attrib.get('y', 0)) or float(get_style_or_attr(elem, 'top') or 0)
            if not y and elem.get('transform'):
                m = re.search(r'translate\(([^,]+)[,\s]+([^)]+)\)', elem.get('transform'))
                if m: y = float(m.group(2))
            
            fill = elem.attrib.get('fill', '')
            font_size = elem.attrib.get('font-size', '')
            font_weight = elem.attrib.get('font-weight', '')
            elements.append({'type': 'text', 'y': y, 'text': text, 'fill': fill, 'size': font_size, 'weight': font_weight})
            
    elif tag == 'rect':
        w = float(elem.attrib.get('width', 0))
        h = float(elem.attrib.get('height', 0))
        if w > 100 and h > 50:
            y = float(elem.attrib.get('y', 0))
            fill = elem.attrib.get('fill', '')
            rx = elem.attrib.get('rx', '')
            elements.append({'type': 'rect', 'y': y, 'w': w, 'h': h, 'fill': fill, 'rx': rx})
            
    elif tag == 'image':
        w = float(elem.attrib.get('width', 0))
        h = float(elem.attrib.get('height', 0))
        y = float(elem.attrib.get('y', 0))
        elements.append({'type': 'image', 'y': y, 'w': w, 'h': h})

elements.sort(key=lambda x: x['y'])

current_y_range = 0
for el in elements:
    if el['type'] == 'rect':
        print(f"RECT: y={el['y']}, w={el['w']}x{el['h']}, fill={el['fill']}, rx={el['rx']}")
    elif el['type'] == 'text':
        print(f"TEXT: y={el['y']}, size={el['size']}, weight={el['weight']}, fill={el['fill']}, text='{el['text']}'")
    elif el['type'] == 'image':
        print(f"IMAGE: y={el['y']}, w={el['w']}x{el['h']}")

