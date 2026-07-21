<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Sửa Cơ Sở — V-SPORT</title>
<script src="https://cdn.tailwindcss.com"></script>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@latest/dist/tabler-icons.min.css"/>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200"/>
<style>
body { font-family: 'Inter', sans-serif; }
  .card { background:#fff;border:1px solid #e4e4e7;border-radius:18px; }
  
  /* Larger Number Input Arrows */
  input[type="number"]::-webkit-inner-spin-button, 
  input[type="number"]::-webkit-outer-spin-button { 
    opacity: 1;
    height: 30px;
    width: 30px;
    cursor: pointer;
  }

  @keyframes fadeUp { from { opacity:0; transform:translateY(10px); } to { opacity:1; transform:translateY(0); } }
  main > section { animation: fadeUp .4s ease both; }
  button { transition: transform .12s ease, opacity .15s ease, background-color .15s ease; }

  @keyframes contentZoomIn {
    from {
      opacity: 0;
      transform: scale(0.97);
    }
    to {
      opacity: 1;
      transform: scale(1);
    }
  }
  main {
    animation: contentZoomIn 0.35s cubic-bezier(0.34, 1.56, 0.64, 1) forwards;
    transform-origin: center top;
  }

  /* Modal animation */
  @keyframes geoFadeIn { from { opacity: 0; } to { opacity: 1; } }
  @keyframes geoScaleUp { from { transform: scale(0.95); opacity: 0; } to { transform: scale(1); opacity: 1; } }
  .geo-animate-fade { animation: geoFadeIn 180ms ease-out forwards; }
  .geo-animate-scale { animation: geoScaleUp 240ms cubic-bezier(.16, 1, .3, 1) forwards; }
</style>
</head>
<body class="bg-zinc-50 text-zinc-900 min-h-screen">

<!-- Sidebar -->
<jsp:include page="/admin/common/sidebar.jsp" />

<!-- Header -->
<jsp:include page="/admin/common/header.jsp">
  <jsp:param name="pageTitle" value="Chỉnh sửa Cơ Sở"/>
</jsp:include>

<!-- Main Content -->
<main class="lg:ml-[260px] mt-[64px] p-4 lg:p-6 flex flex-col items-center text-zinc-900">
  <section class="w-full max-w-[800px]">
    <div class="mb-6 flex items-center gap-2 text-xs font-semibold text-zinc-500">
        <a href="${pageContext.request.contextPath}/admin/chi-nhanh" class="hover:text-zinc-950 transition-colors">Quản lý Cơ Sở</a>
        <i class="ti ti-chevron-right text-[12px]"></i>
        <span class="text-zinc-950 font-bold">${chiNhanh.tenCoSo}</span>
    </div>

    <div class="card p-8 shadow-sm">
      <form action="${pageContext.request.contextPath}/admin/chi-nhanh/sua" method="post" class="flex flex-col gap-6" onsubmit="return validateForm()">
        <input type="hidden" name="id" value="${chiNhanh.coSoID}">
        
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div class="flex flex-col gap-1.5">
                <label class="text-xs font-bold text-zinc-500 uppercase tracking-widest">Tên Cơ Sở</label>
                <input type="text" name="tenCoSo" value="${chiNhanh.tenCoSo}" required class="h-10 px-4 rounded-xl border border-zinc-200 text-sm focus:border-zinc-900 focus:outline-none transition-all font-medium">
            </div>
            
            <div class="flex flex-col gap-1.5">
                <label class="text-xs font-bold text-zinc-500 uppercase tracking-widest">Trạng thái</label>
                <select name="trangThai" class="h-10 px-4 rounded-xl border border-zinc-200 text-sm focus:border-zinc-900 focus:outline-none transition-all font-medium">
                    <option value="Đang hoạt động" ${chiNhanh.trangThai == 'Đang hoạt động' ? 'selected' : ''}>Đang hoạt động</option>
                    <option value="Tạm nghỉ" ${chiNhanh.trangThai == 'Tạm nghỉ' ? 'selected' : ''}>Tạm nghỉ</option>
                </select>
            </div>

            <div class="flex items-center gap-2 px-4 py-3 rounded-xl bg-blue-50/60 border border-blue-100 text-xs text-blue-700 col-span-1 md:col-span-2">
                <i class="ti ti-info-circle text-sm shrink-0"></i>
                <span>Môn thể thao và số sân do Quản lý cơ sở cấu hình tại trang "Quản lý Sân" của chi nhánh — Admin không chỉnh tại đây.</span>
            </div>

            <!-- Địa chỉ + Button định vị -->
            <div class="flex flex-col gap-1.5 col-span-1 md:col-span-2">
                <label class="text-xs font-bold text-zinc-500 uppercase tracking-widest flex items-center justify-between">
                  <span>Địa chỉ</span>
                  <button type="button" onclick="autoFillAddress()" class="flex items-center gap-1.5 text-[11px] font-bold text-blue-600 hover:text-blue-700 bg-blue-50 border border-blue-150 px-2.5 py-1 rounded-lg transition-all normal-case">
                    <i class="ti ti-map-pin text-sm"></i> Định vị địa chỉ / Tọa độ GG Map
                  </button>
                </label>
                <input type="text" id="diaChiInput" name="diaChi" value="${chiNhanh.diaChi}" required class="h-10 px-4 rounded-xl border border-zinc-200 text-sm focus:border-zinc-900 focus:outline-none transition-all font-medium">
                <input type="hidden" id="viDoInput" name="viDo" value="${chiNhanh.viDo}">
                <input type="hidden" id="kinhDoInput" name="kinhDo" value="${chiNhanh.kinhDo}">
                <p id="geoStatus" class="text-[11px] font-semibold mt-0.5 ${empty chiNhanh.viDo ? 'text-amber-600' : 'text-emerald-600'}">
                  <c:choose>
                    <c:when test="${not empty chiNhanh.viDo and not empty chiNhanh.kinhDo}">
                      <i class="ti ti-map-pin-check text-sm align-[-2px]"></i> Đã xác định vị trí (${chiNhanh.viDo}, ${chiNhanh.kinhDo})
                    </c:when>
                    <c:otherwise>
                      <i class="ti ti-map-pin-off text-sm align-[-2px]"></i> Chưa xác định tọa độ — nhấn "Định vị địa chỉ / Tọa độ GG Map"
                    </c:otherwise>
                  </c:choose>
                </p>
            </div>

            <div class="flex flex-col gap-1.5">
                <label class="text-xs font-bold text-zinc-500 uppercase tracking-widest">Số điện thoại</label>
                <input type="text" name="soDienThoai" value="${chiNhanh.soDienThoai}" required class="h-10 px-4 rounded-xl border border-zinc-200 text-sm focus:border-zinc-900 focus:outline-none transition-all font-medium">
            </div>

            <div class="flex flex-col gap-1.5">
                <label class="text-xs font-bold text-zinc-500 uppercase tracking-widest">Giờ mở cửa</label>
                <input type="time" name="gioMoCua" value="${chiNhanh.gioMoCua}" required class="h-10 px-4 rounded-xl border border-zinc-200 text-sm focus:border-zinc-900 focus:outline-none transition-all font-medium">
            </div>

            <div class="flex flex-col gap-1.5">
                <label class="text-xs font-bold text-zinc-500 uppercase tracking-widest">Giờ đóng cửa</label>
                <input type="time" name="gioDongCua" value="${chiNhanh.gioDongCua}" required class="h-10 px-4 rounded-xl border border-zinc-200 text-sm focus:border-zinc-900 focus:outline-none transition-all font-medium">
            </div>
        </div>

        <div class="flex justify-end gap-3 mt-8 pt-6 border-t border-zinc-100">
            <a href="${pageContext.request.contextPath}/admin/chi-nhanh" class="h-10 px-6 rounded-xl border border-zinc-200 text-sm font-semibold text-zinc-600 hover:bg-zinc-50 flex items-center transition-all">Hủy</a>
            <button type="submit" class="h-10 px-8 rounded-xl bg-zinc-900 text-white text-sm font-semibold hover:bg-zinc-800 transition-all shadow-md">Cập nhật Cơ Sở</button>
        </div>
      </form>
    </div>
  </section>
</main>

<!-- Custom Geolocation Modal -->
<div id="geoModal" class="hidden fixed inset-0 z-[100] flex items-center justify-center bg-black/50 backdrop-blur-sm p-4 geo-animate-fade">
  <div class="bg-white border border-zinc-200 rounded-3xl p-6 md:p-8 w-full max-w-md shadow-2xl relative geo-animate-scale">
    <!-- Close button -->
    <button type="button" onclick="closeGeoModal()" class="absolute top-4 right-4 text-zinc-450 hover:text-zinc-800 transition-all bg-transparent border-none cursor-pointer focus:outline-none">
      <i class="ti ti-x text-xl"></i>
    </button>
    
    <div class="flex items-center gap-3 mb-4">
      <div class="w-10 h-10 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center shrink-0 border border-blue-100">
        <i class="ti ti-map-pin text-2xl"></i>
      </div>
      <h3 class="text-lg font-black text-zinc-900">Định vị vị trí Cơ Sở</h3>
    </div>
    
    <p class="text-xs text-zinc-500 mb-6 leading-relaxed">
      Dán tọa độ Google Map (vĩ độ, kinh độ, VD: <code class="text-blue-600 font-bold bg-blue-50 px-1.5 py-0.5 rounded">10.7626, 106.6601</code>) hoặc link bản đồ chứa tọa độ để tự động lấy địa chỉ.
    </p>
    
    <div class="space-y-4 mb-6">
      <div class="flex flex-col gap-1.5">
        <label class="text-xs font-bold text-zinc-700" for="geoInput">Tọa độ hoặc Link Google Map</label>
        <input type="text" id="geoInput" placeholder="Dán tọa độ hoặc link tại đây..." class="w-full px-4 h-11 border border-zinc-200 rounded-xl bg-zinc-50 focus:outline-none focus:ring-2 focus:ring-blue-500/10 focus:border-blue-500 transition-all placeholder:text-zinc-400 text-sm font-medium" />
      </div>
    </div>
    
    <div class="flex flex-col gap-3">
      <button type="button" onclick="submitGeoInput()" class="w-full py-3 text-sm flex justify-center items-center gap-2 text-white bg-blue-600 hover:bg-blue-700 transition-all rounded-xl font-bold shadow-md shadow-blue-100 border-none cursor-pointer">
        <i class="ti ti-search text-base"></i> Xác nhận & Tìm địa chỉ
      </button>
      <button type="button" onclick="useCurrentGps()" id="btnUseGps" class="w-full py-3 text-sm flex justify-center items-center gap-2 text-zinc-700 hover:text-zinc-900 border border-zinc-200 hover:border-zinc-350 bg-zinc-50 hover:bg-zinc-100 transition-all rounded-xl font-bold cursor-pointer">
        <i class="ti ti-device-gps text-base"></i> Sử dụng vị trí GPS hiện tại
      </button>
    </div>
  </div>
</div>

<script>
    document.getElementById('mobileMenuBtn').addEventListener('click', () => {
        document.getElementById('sidebar').classList.toggle('-translate-x-full');
    });

    function validateForm() {
        const viDo = document.getElementById('viDoInput').value;
        const kinhDo = document.getElementById('kinhDoInput').value;
        if (!viDo || !kinhDo) {
            alert('Vị trí cơ sở chưa hợp lệ. Vui lòng chọn lại vị trí trên bản đồ hoặc nhập đầy đủ tọa độ.');
            return false;
        }
        return true;
    }

    // ==========================================
    // GEOLOCATION LOOKUP SCRIPTS
    // ==========================================
    function autoFillAddress() {
        document.getElementById('geoInput').value = "";
        document.getElementById('geoModal').classList.remove('hidden');
        document.getElementById('geoInput').focus();
    }

    function closeGeoModal() {
        document.getElementById('geoModal').classList.add('hidden');
    }

    // Parse tọa độ từ nhiều định dạng: decimal "lat, lon", DMS "10°23'07.3\"N 107°07'20.4\"E",
    // hoặc Google Maps URL chứa "@lat,lon" hay "q=lat,lon". Trả về {lat, lon} hoặc null.
    function parseCoordInput(raw) {
        const input = raw.trim();

        // 1) Google Maps URL: @lat,lon,zoom hoặc ?q=lat,lon hoặc !3dlat!4dlon
        let m = input.match(/@(-?\d+\.\d+),(-?\d+\.\d+)/)
            || input.match(/[?&]q=(-?\d+\.\d+),(-?\d+\.\d+)/)
            || input.match(/!3d(-?\d+\.\d+)!4d(-?\d+\.\d+)/);
        if (m) return { lat: parseFloat(m[1]), lon: parseFloat(m[2]) };

        // 2) DMS: 10°23'07.3"N 107°07'20.4"E (dấu ' và " có thể là ký tự cong)
        const dms = /(\d+)[°\s](\d+)['’′]\s*([\d.]+)[\"”″]?\s*([NSns])[,\s]+(\d+)[°\s](\d+)['’′]\s*([\d.]+)[\"”″]?\s*([EWew])/;
        m = input.match(dms);
        if (m) {
            const toDec = (deg, min, sec, dir) => {
                let v = parseInt(deg, 10) + parseInt(min, 10) / 60 + parseFloat(sec) / 3600;
                if (/[SsWw]/.test(dir)) v = -v;
                return v;
            };
            const lat = toDec(m[1], m[2], m[3], m[4]);
            const lon = toDec(m[5], m[6], m[7], m[8]);
            return { lat: lat, lon: lon };
        }

        // 3) Decimal pair đơn giản: "10.7626, 106.6601"
        m = input.match(/(-?\d+\.\d+)\s*,\s*(-?\d+\.\d+)/);
        if (m) return { lat: parseFloat(m[1]), lon: parseFloat(m[2]) };

        return null;
    }

    function isValidLatLon(lat, lon) {
        return Number.isFinite(lat) && Number.isFinite(lon) && lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180;
    }

    function submitGeoInput() {
        const input = document.getElementById('geoInput').value.trim();
        if (!input) {
            alert("Vui lòng dán tọa độ hoặc link Google Map.");
            return;
        }
        const coord = parseCoordInput(input);
        if (coord && isValidLatLon(coord.lat, coord.lon)) {
            closeGeoModal();
            fetchAddressFromCoords(coord.lat, coord.lon);
        } else {
            alert("Không tìm thấy tọa độ hợp lệ. Ví dụ: 10.7626, 106.6601 hoặc link Google Maps.");
        }
    }

    function useCurrentGps() {
        if (!navigator.geolocation) {
            alert("Trình duyệt không hỗ trợ định vị GPS tự động.");
            return;
        }
        const btn = document.getElementById('btnUseGps');
        const originalText = btn.innerHTML;
        btn.disabled = true;
        btn.innerHTML = '<span class="animate-spin inline-block w-4 h-4 border-2 border-zinc-700 border-t-transparent rounded-full mr-2"></span> Đang định vị GPS...';

        navigator.geolocation.getCurrentPosition(
            function(pos) {
                btn.disabled = false;
                btn.innerHTML = originalText;
                closeGeoModal();
                fetchAddressFromCoords(pos.coords.latitude, pos.coords.longitude);
            },
            function(err) {
                btn.disabled = false;
                btn.innerHTML = originalText;
                let errorMsg = "Lỗi lấy vị trí.";
                if (err.code === err.PERMISSION_DENIED) {
                    errorMsg = "Quyền định vị bị từ chối. Vui lòng cấp quyền hoặc nhập tọa độ thủ công.";
                } else if (err.code === err.POSITION_UNAVAILABLE) {
                    errorMsg = "Không tìm thấy GPS. Vui lòng dán tọa độ Google Map.";
                } else if (err.code === err.TIMEOUT) {
                    errorMsg = "Hết thời gian định vị GPS.";
                }
                alert(errorMsg);
            },
            { enableHighAccuracy: true, timeout: 8000 }
        );
    }

    // Debounce guard: tránh spam Nominatim nếu người dùng bấm định vị liên tục.
    let geoFetchInFlight = false;

    function setGeoStatus(state, lat, lon) {
        const status = document.getElementById('geoStatus');
        if (!status) return;
        if (state === 'ok') {
            status.className = 'text-[11px] font-semibold mt-0.5 text-emerald-600';
            status.innerHTML = '<i class="ti ti-map-pin-check text-sm align-[-2px]"></i> Đã xác định vị trí (' + lat.toFixed(7) + ', ' + lon.toFixed(7) + ')';
        } else if (state === 'partial') {
            status.className = 'text-[11px] font-semibold mt-0.5 text-amber-600';
            status.innerHTML = '<i class="ti ti-map-pin-check text-sm align-[-2px]"></i> Đã lưu tọa độ (' + lat.toFixed(7) + ', ' + lon.toFixed(7) + ') — chưa lấy được địa chỉ chữ, vui lòng nhập tay.';
        } else {
            status.className = 'text-[11px] font-semibold mt-0.5 text-amber-600';
            status.innerHTML = '<i class="ti ti-map-pin-off text-sm align-[-2px]"></i> Chưa xác định tọa độ — nhấn "Định vị địa chỉ / Tọa độ GG Map"';
        }
    }

    function fetchAddressFromCoords(lat, lon) {
        if (!isValidLatLon(lat, lon)) {
            alert("Tọa độ không hợp lệ (vĩ độ -90..90, kinh độ -180..180).");
            return;
        }
        if (geoFetchInFlight) return;
        geoFetchInFlight = true;

        // Lưu tọa độ ngay — dù reverse geocode thất bại vẫn không mất vị trí đã xác định.
        document.getElementById('viDoInput').value = lat;
        document.getElementById('kinhDoInput').value = lon;
        setGeoStatus('partial', lat, lon);

        const addrInput = document.getElementById('diaChiInput');
        const originalPlaceholder = addrInput.placeholder || "";
        addrInput.disabled = true;
        addrInput.value = "";
        addrInput.placeholder = "Đang lấy địa chỉ từ tọa độ [" + parseFloat(lat).toFixed(4) + ", " + parseFloat(lon).toFixed(4) + "]...";

        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 8000);

        fetch('https://nominatim.openstreetmap.org/reverse?format=json&lat=' + lat + '&lon=' + lon + '&accept-language=vi',
              { signal: controller.signal })
            .then(r => r.json())
            .then(data => {
                clearTimeout(timeoutId);
                addrInput.disabled = false;
                addrInput.placeholder = originalPlaceholder;
                if (data && data.display_name) {
                    addrInput.value = data.display_name;
                    setGeoStatus('ok', lat, lon);
                } else {
                    setGeoStatus('partial', lat, lon);
                    alert("Không thể chuyển đổi tọa độ này thành địa chỉ. Tọa độ vẫn được lưu — vui lòng nhập địa chỉ thủ công.");
                }
            })
            .catch(err => {
                clearTimeout(timeoutId);
                addrInput.disabled = false;
                addrInput.placeholder = originalPlaceholder;
                setGeoStatus('partial', lat, lon);
                const msg = (err && err.name === 'AbortError')
                    ? "Hết thời gian chờ dịch vụ địa chỉ. Tọa độ vẫn được lưu — vui lòng nhập địa chỉ thủ công."
                    : "Lỗi kết nối dịch vụ địa chỉ. Tọa độ vẫn được lưu — vui lòng nhập địa chỉ thủ công.";
                alert(msg);
            })
            .finally(() => { geoFetchInFlight = false; });
    }
</script>

</body>
</html>
