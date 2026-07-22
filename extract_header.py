import re

with open('src/main/webapp/index.jsp', 'r', encoding='utf-8') as f:
    content = f.read()

# We want to extract everything from <head> to the end of <div class="bottom-header">...</div>
# Let's just find the header block and extract it.
# Actually, the user wants the header to be a single component.
# Let's extract <header class="header"> ... </header>
header_match = re.search(r'(<header class="header">.*?</header>)', content, re.DOTALL)
if header_match:
    header_html = header_match.group(1)
    # We should add the dropdown for the user in the header!
    # Let's write the header_html to common/header-xtra.jsp
    with open('src/main/webapp/common/header-xtra.jsp', 'w', encoding='utf-8') as out:
        out.write('<%@ page contentType="text/html;charset=UTF-8" language="java" %>\n')
        out.write('<%@ page import="org.example.model.TaiKhoan" %>\n')
        out.write(header_html)
    
    # Replace the header in index.jsp with include
    new_content = content.replace(header_html, '<jsp:include page="/common/header-xtra.jsp" />')
    with open('src/main/webapp/index.jsp', 'w', encoding='utf-8') as out:
        out.write(new_content)
    print("Header extracted and index.jsp updated.")
else:
    print("Header not found!")
