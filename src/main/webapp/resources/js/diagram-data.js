window.diagramCatalog = [
  {
    "id": "D01",
    "slug": "usecase-tong-quat",
    "type": "usecase",
    "chapter": "3.6",
    "title": "Sơ đồ Use Case tổng quát V-SPORT",
    "status": "completed",
    "actors": [
      {
        "id": "a1",
        "name": "Guest"
      },
      {
        "id": "a2",
        "name": "Customer"
      },
      {
        "id": "a3",
        "name": "Staff"
      },
      {
        "id": "a4",
        "name": "Manager"
      },
      {
        "id": "a5",
        "name": "Admin"
      },
      {
        "id": "a6",
        "name": "Dịch vụ Email"
      },
      {
        "id": "a7",
        "name": "PayOS"
      }
    ],
    "nodes": [
      {
        "id": "u1",
        "name": "Đăng ký, xác thực OTP\nQuên mật khẩu"
      },
      {
        "id": "u2",
        "name": "Đăng nhập\n(Email/SDT)"
      },
      {
        "id": "u3",
        "name": "Quản lý cơ sở\nTài khoản"
      },
      {
        "id": "u4",
        "name": "Quản lý sân\nNhân sự\nCa làm việc"
      },
      {
        "id": "u5",
        "name": "Check-in đơn\nMở sân vãng lai"
      },
      {
        "id": "u6",
        "name": "Thêm dịch vụ\nTính tiền, Hóa đơn"
      },
      {
        "id": "u7",
        "name": "Đặt sân"
      },
      {
        "id": "u8",
        "name": "Thanh toán đặt cọc"
      }
    ],
    "relations": [
      {
        "source": "a1",
        "target": "u1",
        "type": "association"
      },
      {
        "source": "a1",
        "target": "u2",
        "type": "association"
      },
      {
        "source": "a2",
        "target": "u7",
        "type": "association"
      },
      {
        "source": "a2",
        "target": "u8",
        "type": "association"
      },
      {
        "source": "a3",
        "target": "u5",
        "type": "association"
      },
      {
        "source": "a3",
        "target": "u6",
        "type": "association"
      },
      {
        "source": "a4",
        "target": "u4",
        "type": "association"
      },
      {
        "source": "a4",
        "target": "u6",
        "type": "association"
      },
      {
        "source": "a5",
        "target": "u3",
        "type": "association"
      },
      {
        "source": "u1",
        "target": "a6",
        "type": "association"
      },
      {
        "source": "u8",
        "target": "a7",
        "type": "association"
      }
    ],
    "notes": [
      "V-SPORT – Hệ thống quản lý chuỗi sân thể thao"
    ],
    "sourceFiles": []
  },
  {
    "id": "UC01",
    "slug": "usecase-uc01",
    "type": "usecase_detail",
    "chapter": "3.7",
    "title": "UC01. Đăng ký và xác thực OTP",
    "status": "completed",
    "actors": [
      {
        "id": "a1",
        "name": "Guest"
      }
    ],
    "nodes": [
      {
        "id": "u1",
        "name": "Đăng ký và xác thực OTP"
      }
    ],
    "relations": [
      {
        "source": "a1",
        "target": "u1",
        "type": "association"
      }
    ],
    "purpose": "Tạo tài khoản Customer hợp lệ.",
    "precondition": "Người dùng chưa đăng nhập; email/username chưa tồn tại.",
    "main_flow": "1. Mở biểu mẫu đăng ký.2. Nhập thông tin và gửi form.3. Servlet chuẩn hóa và validation dữ liệu.4. Hệ thống băm mật khẩu, tạo tài khoản tạm và gửi OTP.5. Người dùng nhập OTP.6. Hệ thống xác thực OTP và lưu tài khoản.7. Chuyển về màn hình đăng nhập.",
    "alt_flow": "1. Dữ liệu thiếu/sai: hiển thị lỗi và giữ dữ liệu phù hợp.2. Email/username trùng: từ chối đăng ký.3. OTP sai/hết hạn: không lưu tài khoản và cho phép gửi lại theo quy tắc.",
    "postcondition": "Tài khoản Customer được tạo; OTP tạm được xóa khỏi Session.",
    "sourceFiles": [
      "DangKyServlet",
      "XacThucOTPServlet",
      "TaiKhoanDAOImpl",
      "EmailUtil",
      "DangKy.jsp",
      "NhapMa.jsp"
    ]
  },
  {
    "id": "UC02",
    "slug": "usecase-uc02",
    "type": "usecase_detail",
    "chapter": "3.7",
    "title": "UC02. Đăng nhập và tạo Session",
    "status": "completed",
    "actors": [
      {
        "id": "a1",
        "name": "Guest"
      }
    ],
    "nodes": [
      {
        "id": "u1",
        "name": "Đăng nhập và tạo Session"
      }
    ],
    "relations": [
      {
        "source": "a1",
        "target": "u1",
        "type": "association"
      }
    ],
    "purpose": "Xác thực người dùng và điều hướng đúng Role.",
    "precondition": "Tài khoản tồn tại, không bị xóa/khóa theo logic DAO.",
    "main_flow": "1. Nhập username/email và mật khẩu.2. DangNhapServlet kiểm tra dữ liệu rỗng.3. DAO tìm tài khoản và kiểm tra BCrypt.4. Hủy Session cũ nếu có.5. Tạo Session mới và lưu user, roleId, accountId, fullName, email.6. Điều hướng đến trang chủ theo Role.",
    "alt_flow": "1. Thông tin sai: hiển thị lỗi.2. Database lỗi: hiển thị thông báo cấu hình/kết nối phù hợp.3. Đã đăng nhập: GET /dangnhap điều hướng về trang Role.",
    "postcondition": "Session xác thực tồn tại và người dùng vào đúng dashboard.",
    "sourceFiles": [
      "DangNhapServlet",
      "TaiKhoanDAOImpl",
      "RoleRedirectUtil",
      "SessionUtil"
    ]
  },
  {
    "id": "UC03",
    "slug": "usecase-uc03",
    "type": "usecase_detail",
    "chapter": "3.7",
    "title": "UC03. Quên mật khẩu",
    "status": "completed",
    "actors": [
      {
        "id": "a1",
        "name": "Guest"
      }
    ],
    "nodes": [
      {
        "id": "u1",
        "name": "Quên mật khẩu"
      }
    ],
    "relations": [
      {
        "source": "a1",
        "target": "u1",
        "type": "association"
      }
    ],
    "purpose": "Đặt lại mật khẩu thông qua email OTP.",
    "precondition": "Email đã đăng ký trong hệ thống.",
    "main_flow": "1. Nhập email.2. Hệ thống kiểm tra email.3. Gửi OTP và lưu authType/resetEmail trong Session.4. Người dùng nhập OTP.5. Hệ thống đánh dấu isVerified.6. Người dùng nhập mật khẩu mới và xác nhận.7. Hệ thống validation, băm và cập nhật mật khẩu.",
    "alt_flow": "1. Email không tồn tại: báo lỗi.2. OTP sai: không cho sang bước nhập mật khẩu.3. Mật khẩu yếu/không khớp: từ chối cập nhật.",
    "postcondition": "Mật khẩu mới được lưu; dữ liệu OTP/reset trong Session được xóa.",
    "sourceFiles": [
      "QuenMatKhauServlet",
      "XacThucOTPServlet",
      "DatLaiMatKhauServlet",
      "NhapMatKauMoi.jsp"
    ]
  },
  {
    "id": "UC04",
    "slug": "usecase-uc04",
    "type": "usecase_detail",
    "chapter": "3.7",
    "title": "UC04. Admin quản lý chi nhánh",
    "status": "completed",
    "actors": [
      {
        "id": "a1",
        "name": "Admin"
      }
    ],
    "nodes": [
      {
        "id": "u1",
        "name": "Admin quản lý chi nhánh"
      }
    ],
    "relations": [
      {
        "source": "a1",
        "target": "u1",
        "type": "association"
      }
    ],
    "purpose": "Tạo và duy trì thông tin cơ sở.",
    "precondition": "Admin đã đăng nhập và qua FilterQuyenAdmin.",
    "main_flow": "1. Mở danh sách chi nhánh.2. Chọn thêm hoặc sửa.3. Nhập thông tin cơ sở và cấu hình sân.4. Servlet validation và gọi DAO.5. Hệ thống lưu thay đổi, đồng bộ sân khi cần.6. Ghi kết quả và điều hướng lại danh sách.",
    "alt_flow": "1. Dữ liệu không hợp lệ: báo lỗi.2. Cơ sở có ràng buộc: sử dụng xóa mềm/thùng rác.3. Không đủ quyền: bị Filter chặn.",
    "postcondition": "Thông tin CoSo và các sân liên quan được cập nhật nhất quán.",
    "sourceFiles": [
      "QuanLyChiNhanhServlet",
      "CoSoDAO",
      "FacilityTrashService",
      "QuanLyChiNhanh.jsp"
    ]
  },
  {
    "id": "UC05",
    "slug": "usecase-uc05",
    "type": "usecase_detail",
    "chapter": "3.7",
    "title": "UC05. Admin quản lý tài khoản",
    "status": "completed",
    "actors": [
      {
        "id": "a1",
        "name": "Admin"
      }
    ],
    "nodes": [
      {
        "id": "u1",
        "name": "Admin quản lý tài khoản"
      }
    ],
    "relations": [
      {
        "source": "a1",
        "target": "u1",
        "type": "association"
      }
    ],
    "purpose": "Thêm, sửa, khóa hoặc xóa mềm tài khoản.",
    "precondition": "Admin đã đăng nhập.",
    "main_flow": "1. Mở trang nhân sự/tài khoản.2. Chọn thao tác.3. Nhập dữ liệu và Role/CoSo phù hợp.4. Servlet kiểm tra trùng và validation.5. Nếu luồng yêu cầu OTP, gửi và xác thực OTP.6. DAO lưu dữ liệu.7. Hiển thị thông báo kết quả.",
    "alt_flow": "1. Email/username trùng: từ chối.2. Role/CoSo không hợp lệ: từ chối.3. OTP sai quá số lần: hủy thao tác.",
    "postcondition": "Tài khoản được cập nhật đúng và có thể truy vết.",
    "sourceFiles": [
      "QuanLyNguoiDungServlet",
      "XacThucOTPServlet",
      "TaiKhoanDAO",
      "AdminTrashDAO"
    ]
  },
  {
    "id": "UC06",
    "slug": "usecase-uc06",
    "type": "usecase_detail",
    "chapter": "3.7",
    "title": "UC06. Manager quản lý sân",
    "status": "completed",
    "actors": [
      {
        "id": "a1",
        "name": "Manager"
      }
    ],
    "nodes": [
      {
        "id": "u1",
        "name": "Manager quản lý sân"
      }
    ],
    "relations": [
      {
        "source": "a1",
        "target": "u1",
        "type": "association"
      }
    ],
    "purpose": "Quản lý sân thuộc cơ sở phụ trách.",
    "precondition": "Manager đã đăng nhập và có CoSoID.",
    "main_flow": "1. Mở trang quản lý sân.2. Hệ thống tải danh sách theo CoSoID.3. Manager thêm/sửa/thay đổi trạng thái sân.4. Servlet và Service validation dữ liệu.5. DAO lưu thay đổi.6. Audit Log được ghi khi chức năng hỗ trợ.",
    "alt_flow": "1. Truy cập sân ngoài cơ sở: từ chối.2. Tên/loại sân/giá không hợp lệ: báo lỗi.3. Sân đang sử dụng: hạn chế thao tác nguy hiểm.",
    "postcondition": "Dữ liệu sân của cơ sở được cập nhật.",
    "sourceFiles": [
      "QuanLySanManagerServlet",
      "SanService",
      "SanDAO",
      "BranchSecurityUtils"
    ]
  },
  {
    "id": "UC07",
    "slug": "usecase-uc07",
    "type": "usecase_detail",
    "chapter": "3.7",
    "title": "UC07. Customer đặt sân",
    "status": "completed",
    "actors": [
      {
        "id": "a1",
        "name": "Customer"
      }
    ],
    "nodes": [
      {
        "id": "u1",
        "name": "Customer đặt sân"
      }
    ],
    "relations": [
      {
        "source": "a1",
        "target": "u1",
        "type": "association"
      }
    ],
    "purpose": "Tạo đơn đặt sân không trùng lịch.",
    "precondition": "Customer đã đăng nhập; sân hoạt động và thuộc cơ sở hợp lệ.",
    "main_flow": "1. Chọn cơ sở, sân, ngày, giờ và phương thức thanh toán.2. Tạo/kiểm tra Soft Hold khi thao tác.3. Servlet validation đầu vào.4. Bắt đầu transaction và khóa dữ liệu sân.5. Kiểm tra overlap theo trạng thái chặn lịch.6. Tính tiền dự kiến.7. Ghi LichDatSan và hóa đơn/giữ chỗ tương ứng.8. Commit và trả kết quả.",
    "alt_flow": "1. Khung giờ trùng: rollback và yêu cầu chọn lại.2. Deadlock/tạm lỗi: retry theo logic hiện có.3. Dữ liệu sai: không mở transaction ghi dữ liệu.",
    "postcondition": "Một đơn hợp lệ được tạo; khung giờ được giữ theo trạng thái và thời hạn.",
    "sourceFiles": [
      "DatSanServlet",
      "GiuChoTamServlet",
      "SoftHoldDAO",
      "LichDatSanDAO",
      "DatSan.jsp"
    ]
  },
  {
    "id": "UC08",
    "slug": "usecase-uc08",
    "type": "usecase_detail",
    "chapter": "3.7",
    "title": "UC08. Thanh toán đặt cọc PayOS",
    "status": "completed",
    "actors": [
      {
        "id": "a1",
        "name": "Customer"
      },
      {
        "id": "a1",
        "name": "PayOS"
      }
    ],
    "nodes": [
      {
        "id": "u1",
        "name": "Thanh toán đặt cọc PayOS"
      }
    ],
    "relations": [
      {
        "source": "a1",
        "target": "u1",
        "type": "association"
      }
    ],
    "purpose": "Xác nhận thanh toán online cho đơn đặt sân.",
    "precondition": "Đơn ở trạng thái chờ thanh toán và còn thời hạn giữ chỗ.",
    "main_flow": "1. Hệ thống tạo checkout session PayOS.2. Customer quét QR/thanh toán.3. PayOS gọi webhook hoặc trả về return URL.4. Hệ thống xác thực dữ liệu giao dịch.5. Cập nhật mã giao dịch, phương thức, thời điểm xác nhận và trạng thái đơn/hóa đơn.6. Hiển thị kết quả cho Customer.",
    "alt_flow": "1. Thanh toán bị hủy: giữ trạng thái theo chính sách cho đến khi hết hạn.2. Webhook không hợp lệ: không cập nhật dữ liệu.3. Đơn đã quá hạn: không xác nhận sai khung giờ.",
    "postcondition": "Đơn và hóa đơn phản ánh đúng trạng thái giao dịch.",
    "sourceFiles": [
      "PayOSService",
      "PayOSWebhookServlet",
      "DatSanServlet"
    ]
  },
  {
    "id": "UC09",
    "slug": "usecase-uc09",
    "type": "usecase_detail",
    "chapter": "3.7",
    "title": "UC09. Staff check-in đơn đặt trước",
    "status": "completed",
    "actors": [
      {
        "id": "a1",
        "name": "Staff"
      }
    ],
    "nodes": [
      {
        "id": "u1",
        "name": "Staff check-in đơn đặt trước"
      }
    ],
    "relations": [
      {
        "source": "a1",
        "target": "u1",
        "type": "association"
      }
    ],
    "purpose": "Mở sân cho đơn hợp lệ.",
    "precondition": "Staff thuộc cơ sở; đơn đúng ngày/giờ và sân Sẵn sàng.",
    "main_flow": "1. Mở trang Check-in.2. Chọn đơn đặt trước.3. Hệ thống khóa và đọc đơn/sân/hóa đơn.4. Kiểm tra trạng thái đặt và thanh toán.5. Xác nhận thu tiền tại quầy nếu luồng cho phép.6. Cập nhật đơn thành Đang sử dụng và actual_start_time.7. Cập nhật sân thành Đang sử dụng.",
    "alt_flow": "1. Sân không Sẵn sàng: từ chối.2. Đơn đã Đang sử dụng: không mở lần hai.3. Đơn không thuộc cơ sở: từ chối.",
    "postcondition": "Phiên sử dụng được mở nhất quán.",
    "sourceFiles": [
      "CheckInServlet",
      "CheckInDAO",
      "CheckIn.jsp"
    ]
  },
  {
    "id": "UC10",
    "slug": "usecase-uc10",
    "type": "usecase_detail",
    "chapter": "3.7",
    "title": "UC10. Staff mở sân khách vãng lai và kết thúc phiên",
    "status": "completed",
    "actors": [
      {
        "id": "a1",
        "name": "Staff"
      }
    ],
    "nodes": [
      {
        "id": "u1",
        "name": "Staff mở sân khách vãng lai và kết thúc phiên"
      }
    ],
    "relations": [
      {
        "source": "a1",
        "target": "u1",
        "type": "association"
      }
    ],
    "purpose": "Tạo phiên trực tiếp, tính tiền theo chế độ thời gian và chốt hóa đơn.",
    "precondition": "Sân Sẵn sàng; Staff thuộc cơ sở.",
    "main_flow": "1. Chọn sân và chế độ giờ cố định/không cố định.2. Nhập thông tin khách và thời lượng nếu có.3. Hệ thống kiểm tra xung đột.4. Tạo LichDatSan trạng thái Đang sử dụng và hóa đơn chưa thanh toán.5. Khi khách kết thúc, Staff chọn dừng phiên.6. Hệ thống ghi actual_end_time, tính tiền sân/dịch vụ/giảm trừ hợp lệ.7. Xác nhận phương thức thanh toán và đóng hóa đơn.8. Chuyển sân về Sẵn sàng.",
    "alt_flow": "1. Dừng sớm giờ cố định: yêu cầu lý do và xử lý giảm trừ theo logic hỗ trợ.2. Dịch vụ chưa hợp lệ: không chốt sai tổng tiền.3. Thanh toán lỗi: hóa đơn không được đánh dấu đã trả.",
    "postcondition": "Phiên kết thúc; sân được giải phóng; hóa đơn có thể in.",
    "sourceFiles": [
      "CheckInServlet",
      "CheckInDAO",
      "HoaDonDAO",
      "HoaDonPrintServlet"
    ]
  },
  {
    "id": "UC11",
    "slug": "usecase-uc11",
    "type": "usecase_detail",
    "chapter": "3.7",
    "title": "UC11. Thêm dịch vụ và in hóa đơn",
    "status": "completed",
    "actors": [
      {
        "id": "a1",
        "name": "Staff"
      },
      {
        "id": "a1",
        "name": "Manager"
      }
    ],
    "nodes": [
      {
        "id": "u1",
        "name": "Thêm dịch vụ và in hóa đơn"
      }
    ],
    "relations": [
      {
        "source": "a1",
        "target": "u1",
        "type": "association"
      }
    ],
    "purpose": "Ghi nhận dịch vụ phát sinh và xuất hóa đơn rõ ràng.",
    "precondition": "Có đơn/phiên sử dụng và sản phẩm còn hoạt động.",
    "main_flow": "1. Tìm sản phẩm theo cơ sở.2. Chọn số lượng.3. Hệ thống kiểm tra tồn và đơn giá.4. Ghi chi tiết dịch vụ/chi tiết hóa đơn.5. Cập nhật tổng tiền dịch vụ và tổng thanh toán.6. Chọn in hóa đơn.7. HoaDonPrintServlet tải dữ liệu và chuyển đến HoaDonPrint.jsp.",
    "alt_flow": "1. Số lượng không hợp lệ hoặc vượt tồn: từ chối.2. Hóa đơn đã đóng/hủy: không thêm mới.3. Không đúng cơ sở: không cho truy cập sản phẩm.",
    "postcondition": "Hóa đơn và tồn kho phản ánh đúng giao dịch.",
    "sourceFiles": [
      "CheckInServlet",
      "KhoDichVuManagerServlet",
      "HoaDonDAO",
      "HoaDonPrintServlet"
    ]
  },
  {
    "id": "UC12",
    "slug": "usecase-uc12",
    "type": "usecase_detail",
    "chapter": "3.7",
    "title": "UC12. Manager quản lý ca làm việc",
    "status": "completed",
    "actors": [
      {
        "id": "a1",
        "name": "Manager"
      }
    ],
    "nodes": [
      {
        "id": "u1",
        "name": "Manager quản lý ca làm việc"
      }
    ],
    "relations": [
      {
        "source": "a1",
        "target": "u1",
        "type": "association"
      }
    ],
    "purpose": "Tạo và điều phối ca làm hợp lệ.",
    "precondition": "Manager đã đăng nhập; nhân viên thuộc cơ sở.",
    "main_flow": "1. Mở lịch ca.2. Chọn nhân viên/ngày/mẫu ca hoặc thời gian tùy chỉnh.3. Validation thời gian, lý do tùy chỉnh và xung đột.4. Service/DAO lưu ca.5. Manager công bố hoặc cập nhật theo trạng thái cho phép.6. Hệ thống ghi lịch sử thay đổi.",
    "alt_flow": "1. Ca trùng: báo Conflict.2. Nhân viên ngoài cơ sở: Forbidden.3. Ca đã check-in/check-out/hoàn thành: không cho sửa/hủy trái quy định.",
    "postcondition": "Lịch ca hợp lệ được lưu và hiển thị cho Staff.",
    "sourceFiles": [
      "QuanLyCaLamManagerServlet",
      "CaLamService",
      "CaLamValidationEngine",
      "CaLamViecDAO"
    ]
  },
  {
    "id": "UC13",
    "slug": "usecase-uc13",
    "type": "usecase_detail",
    "chapter": "3.7",
    "title": "UC13. Staff gửi và Manager xử lý yêu cầu nghỉ",
    "status": "completed",
    "actors": [
      {
        "id": "a1",
        "name": "Staff"
      },
      {
        "id": "a1",
        "name": "Manager"
      }
    ],
    "nodes": [
      {
        "id": "u1",
        "name": "Staff gửi và Manager xử lý yêu cầu nghỉ"
      }
    ],
    "relations": [
      {
        "source": "a1",
        "target": "u1",
        "type": "association"
      }
    ],
    "purpose": "Quản lý yêu cầu nghỉ có trạng thái và người xử lý.",
    "precondition": "Staff có tài khoản/cơ sở; ngày nghỉ và lý do hợp lệ.",
    "main_flow": "1. Staff mở form và gửi yêu cầu.2. Service kiểm tra dữ liệu và ca bị ảnh hưởng.3. Lưu yêu cầu trạng thái chờ xử lý.4. Manager xem danh sách theo cơ sở.5. Manager duyệt hoặc từ chối, nhập ghi chú.6. Hệ thống lưu người và thời gian xử lý.",
    "alt_flow": "1. Yêu cầu trùng/không hợp lệ: từ chối.2. Manager ngoài cơ sở: không được xử lý.3. Yêu cầu đã xử lý: không xử lý lại.",
    "postcondition": "Yêu cầu nghỉ có kết quả và có thể truy vết.",
    "sourceFiles": [
      "YeuCauNghiStaffServlet",
      "YeuCauNghiManagerServlet",
      "YeuCauNghiService"
    ]
  },
  {
    "id": "UC14",
    "slug": "usecase-uc14",
    "type": "usecase_detail",
    "chapter": "3.7",
    "title": "UC14. Xóa mềm, khôi phục và Audit Log",
    "status": "completed",
    "actors": [
      {
        "id": "a1",
        "name": "Admin"
      },
      {
        "id": "a1",
        "name": "Manager"
      }
    ],
    "nodes": [
      {
        "id": "u1",
        "name": "Xóa mềm, khôi phục và Audit Log"
      }
    ],
    "relations": [
      {
        "source": "a1",
        "target": "u1",
        "type": "association"
      }
    ],
    "purpose": "Hạn chế mất dữ liệu và ghi nhận thao tác quan trọng.",
    "precondition": "Người dùng có quyền với loại dữ liệu và cơ sở tương ứng.",
    "main_flow": "1. Người dùng chọn xóa.2. Hệ thống đánh dấu IsDeleted, DeletedAt, DeletedBy.3. Bản ghi không còn xuất hiện trong danh sách hoạt động.4. Bản ghi xuất hiện trong thùng rác phù hợp.5. Người có quyền chọn khôi phục hoặc xử lý tiếp.6. Audit Log lưu actor, action, entity và thời điểm.",
    "alt_flow": "1. Dữ liệu có ràng buộc không thể xóa cứng: giữ xóa mềm.2. Không đúng quyền/cơ sở: từ chối.3. Bản ghi không tồn tại: báo NotFound.",
    "postcondition": "Dữ liệu vẫn có khả năng truy vết và khôi phục.",
    "sourceFiles": [
      "AdminTrashServlet",
      "ThungRacManagerServlet",
      "AuditLogService",
      "AuditLogDAO"
    ]
  },
  {
    "id": "D02",
    "slug": "architecture",
    "type": "architecture",
    "chapter": "4.1",
    "title": "Sơ đồ kiến trúc tổng quan V-SPORT",
    "status": "completed"
  },
  {
    "id": "D03",
    "slug": "mvc",
    "type": "mvc",
    "chapter": "4.2",
    "title": "Sơ đồ mô hình MVC",
    "status": "completed"
  },
  {
    "id": "D04",
    "slug": "erd",
    "type": "erd",
    "chapter": "4.5",
    "title": "Sơ đồ ERD của phiên bản V-SPORT hiện tại",
    "status": "completed"
  },
  {
    "id": "D05",
    "slug": "class",
    "type": "class",
    "chapter": "4.6",
    "title": "Class Diagram các module xác thực, đặt sân, check-in, hóa đơn và ca làm việc",
    "status": "completed"
  },
  {
    "id": "D06",
    "slug": "sequence-1",
    "type": "sequence",
    "chapter": "5.1",
    "title": "Sequence 1. Đăng ký và xác thực OTP",
    "status": "completed"
  },
  {
    "id": "D07",
    "slug": "sequence-2",
    "type": "sequence",
    "chapter": "5.1",
    "title": "Sequence 2. Đăng nhập và phân quyền",
    "status": "completed"
  },
  {
    "id": "D08",
    "slug": "sequence-3",
    "type": "sequence",
    "chapter": "5.1",
    "title": "Sequence 3. Đặt sân và thanh toán PayOS",
    "status": "completed"
  },
  {
    "id": "D09",
    "slug": "sequence-4",
    "type": "sequence",
    "chapter": "5.1",
    "title": "Sequence 4. Check-in và mở sân khách vãng lai",
    "status": "completed"
  },
  {
    "id": "D010",
    "slug": "sequence-5",
    "type": "sequence",
    "chapter": "5.1",
    "title": "Sequence 5. Thêm dịch vụ và hóa đơn",
    "status": "completed"
  },
  {
    "id": "D011",
    "slug": "sequence-6",
    "type": "sequence",
    "chapter": "5.1",
    "title": "Sequence 6. Quản lý ca làm việc và yêu cầu nghỉ",
    "status": "completed"
  },
  {
    "id": "D12",
    "slug": "activity-1",
    "type": "activity",
    "chapter": "5.2",
    "title": "Activity 1. Hoạt động đăng ký tài khoản",
    "status": "completed"
  },
  {
    "id": "D13",
    "slug": "activity-2",
    "type": "activity",
    "chapter": "5.2",
    "title": "Activity 2. Hoạt động đăng nhập",
    "status": "completed"
  },
  {
    "id": "D14",
    "slug": "activity-3",
    "type": "activity",
    "chapter": "5.2",
    "title": "Activity 3. Hoạt động đặt sân",
    "status": "completed"
  },
  {
    "id": "D15",
    "slug": "activity-4",
    "type": "activity",
    "chapter": "5.2",
    "title": "Activity 4. Hoạt động check-in và checkout",
    "status": "completed"
  },
  {
    "id": "D16",
    "slug": "activity-5",
    "type": "activity",
    "chapter": "5.2",
    "title": "Activity 5. Hoạt động quản lý ca",
    "status": "completed"
  },
  {
    "id": "D17",
    "slug": "activity-6",
    "type": "activity",
    "chapter": "5.2",
    "title": "Activity 6. Hoạt động yêu cầu nghỉ",
    "status": "completed"
  },
  {
    "id": "D18",
    "slug": "survey",
    "type": "chart",
    "chapter": "2.7",
    "title": "Biểu đồ kết quả khảo sát",
    "status": "pending"
  },
  {
    "id": "D19",
    "slug": "test-results",
    "type": "chart",
    "chapter": "6.8",
    "title": "Biểu đồ kết quả kiểm thử",
    "status": "pending"
  }
];
