import re
import json

with open('docx_extracted.txt', 'r', encoding='utf-8') as f:
    text = f.read()

diagrams = []

# D01 - General Use Case
diagrams.append({
    "id": "D01",
    "slug": "usecase-tong-quat",
    "type": "usecase",
    "chapter": "3.6",
    "title": "Sơ đồ Use Case tổng quát V-SPORT",
    "status": "completed",
    "actors": [
        {"id": "a1", "name": "Guest"},
        {"id": "a2", "name": "Customer"},
        {"id": "a3", "name": "Staff"},
        {"id": "a4", "name": "Manager"},
        {"id": "a5", "name": "Admin"},
        {"id": "a6", "name": "Dịch vụ Email"},
        {"id": "a7", "name": "PayOS"}
    ],
    "nodes": [
        {"id": "u1", "name": "Đăng ký, xác thực OTP\nQuên mật khẩu"},
        {"id": "u2", "name": "Đăng nhập\n(Email/SDT)"},
        {"id": "u3", "name": "Quản lý cơ sở\nTài khoản"},
        {"id": "u4", "name": "Quản lý sân\nNhân sự\nCa làm việc"},
        {"id": "u5", "name": "Check-in đơn\nMở sân vãng lai"},
        {"id": "u6", "name": "Thêm dịch vụ\nTính tiền, Hóa đơn"},
        {"id": "u7", "name": "Đặt sân"},
        {"id": "u8", "name": "Thanh toán đặt cọc"}
    ],
    "relations": [
        {"source": "a1", "target": "u1", "type": "association"},
        {"source": "a1", "target": "u2", "type": "association"},
        {"source": "a2", "target": "u7", "type": "association"},
        {"source": "a2", "target": "u8", "type": "association"},
        {"source": "a3", "target": "u5", "type": "association"},
        {"source": "a3", "target": "u6", "type": "association"},
        {"source": "a4", "target": "u4", "type": "association"},
        {"source": "a4", "target": "u6", "type": "association"},
        {"source": "a5", "target": "u3", "type": "association"},
        {"source": "u1", "target": "a6", "type": "association"},
        {"source": "u8", "target": "a7", "type": "association"}
    ],
    "notes": ["V-SPORT – Hệ thống quản lý chuỗi sân thể thao"],
    "sourceFiles": []
})

# Use Cases UC01-UC14
uc_pattern = re.compile(r'(UC\d\d)\.\s*(.*?)\n.*?Mã Use Case\n\1\n.*?Tên Use Case\n(.*?)\n.*?Actor\n(.*?)\n.*?Mục đích\n(.*?)\n.*?Điều kiện trước\n(.*?)\n.*?Luồng chính\n(.*?)\n.*?Luồng thay thế/ngoại lệ\n(.*?)\n.*?Điều kiện sau\n(.*?)\n.*?Thành phần source liên quan\n(.*?)\n', re.DOTALL)
for match in uc_pattern.finditer(text):
    uc_id = match.group(1)
    uc_name = match.group(2).strip()
    actor = match.group(4).strip()
    purpose = match.group(5).strip()
    precondition = match.group(6).strip()
    main_flow = match.group(7).strip()
    alt_flow = match.group(8).strip()
    postcondition = match.group(9).strip()
    source_files = [x.strip() for x in match.group(10).replace(';', ',').split(',')]
    
    diagrams.append({
        "id": uc_id,
        "slug": f"usecase-{uc_id.lower()}",
        "type": "usecase_detail",
        "chapter": "3.7",
        "title": f"{uc_id}. {uc_name}",
        "status": "completed",
        "actors": [{"id": "a1", "name": a.strip()} for a in actor.split('/')],
        "nodes": [{"id": "u1", "name": uc_name}],
        "relations": [{"source": "a1", "target": "u1", "type": "association"}],
        "purpose": purpose,
        "precondition": precondition,
        "main_flow": main_flow,
        "alt_flow": alt_flow,
        "postcondition": postcondition,
        "sourceFiles": source_files
    })

# Add Architecture, MVC, ERD, Class, Sequences, Activities
diagrams.extend([
    {
        "id": "D02", "slug": "architecture", "type": "architecture", "chapter": "4.1", "title": "Sơ đồ kiến trúc tổng quan V-SPORT", "status": "completed"
    },
    {
        "id": "D03", "slug": "mvc", "type": "mvc", "chapter": "4.2", "title": "Sơ đồ mô hình MVC", "status": "completed"
    },
    {
        "id": "D04", "slug": "erd", "type": "erd", "chapter": "4.5", "title": "Sơ đồ ERD của phiên bản V-SPORT hiện tại", "status": "completed"
    },
    {
        "id": "D05", "slug": "class", "type": "class", "chapter": "4.6", "title": "Class Diagram các module xác thực, đặt sân, check-in, hóa đơn và ca làm việc", "status": "completed"
    }
])

seq_names = [
    "Đăng ký và xác thực OTP", "Đăng nhập và phân quyền", "Đặt sân và thanh toán PayOS",
    "Check-in và mở sân khách vãng lai", "Thêm dịch vụ và hóa đơn", "Quản lý ca làm việc và yêu cầu nghỉ"
]
for i, name in enumerate(seq_names):
    diagrams.append({
        "id": f"D0{6+i}", "slug": f"sequence-{i+1}", "type": "sequence", "chapter": "5.1",
        "title": f"Sequence {i+1}. {name}", "status": "completed"
    })

act_names = [
    "Hoạt động đăng ký tài khoản", "Hoạt động đăng nhập", "Hoạt động đặt sân",
    "Hoạt động check-in và checkout", "Hoạt động quản lý ca", "Hoạt động yêu cầu nghỉ"
]
for i, name in enumerate(act_names):
    diagrams.append({
        "id": f"D{12+i}", "slug": f"activity-{i+1}", "type": "activity", "chapter": "5.2",
        "title": f"Activity {i+1}. {name}", "status": "completed"
    })

diagrams.extend([
    {
        "id": "D18", "slug": "survey", "type": "chart", "chapter": "2.7", "title": "Biểu đồ kết quả khảo sát", "status": "pending"
    },
    {
        "id": "D19", "slug": "test-results", "type": "chart", "chapter": "6.8", "title": "Biểu đồ kết quả kiểm thử", "status": "pending"
    }
])

js_content = f"const diagramCatalog = {json.dumps(diagrams, ensure_ascii=False, indent=2)};\n"
with open('diagram-data.js', 'w', encoding='utf-8') as f:
    f.write(js_content)
