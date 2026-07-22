package org.example.dao;

import org.example.model.CoSoCapability;

import java.util.List;

public interface CoSoCapabilityDAO {
    List<CoSoCapability> findByCoSoId(int coSoId);
    CoSoCapability findByCoSoIdAndType(int coSoId, String capabilityType);
    CoSoCapability findById(int capabilityId);
    boolean isApproved(int coSoId, String capabilityType);
    /** True nếu ít nhất một trong các capabilityTypes đang APPROVED cho cơ sở này. */
    boolean isApprovedAny(int coSoId, List<String> capabilityTypes);
    /** Tổng số sản phẩm/loại hình cùng trạng thái APPROVED của một cơ sở, ví dụ để hiển thị tab. */
    List<String> findApprovedTypes(int coSoId);
}
