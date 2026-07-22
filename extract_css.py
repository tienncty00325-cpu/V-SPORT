import re

with open('src/main/webapp/index.jsp', 'r', encoding='utf-8') as f:
    content = f.read()

head_match = re.search(r'(<head>.*?</head>)', content, re.DOTALL)
if head_match:
    head_html = head_match.group(1)
    with open('src/main/webapp/common/xtra-head.jsp', 'w', encoding='utf-8') as out:
        out.write('<%@ page contentType="text/html;charset=UTF-8" language="java" %>\n')
        out.write(head_html)
    
    # Replace in index.jsp
    new_content = content.replace(head_html, '<jsp:include page="/common/xtra-head.jsp" />')
    with open('src/main/webapp/index.jsp', 'w', encoding='utf-8') as out:
        out.write(new_content)
    print("Head extracted and index.jsp updated.")
else:
    print("Head not found!")
