package org.example.dao.impl;

import org.example.dao.DanhMucSanPhamDAO;
import org.example.model.DanhMucSanPham;
import org.example.util.JPAUtil;

import jakarta.persistence.EntityManager;
import jakarta.persistence.EntityTransaction;
import java.util.List;

public class DanhMucSanPhamDAOImpl implements DanhMucSanPhamDAO {

    private EntityManager getEntityManager() {
        return JPAUtil.getEntityManager();
    }

    @Override
    public List<DanhMucSanPham> findAll() {
        EntityManager em = getEntityManager();
        try {
            return em.createQuery("SELECT c FROM DanhMucSanPham c ORDER BY c.TenDanhMuc ASC", DanhMucSanPham.class).getResultList();
        } finally {
            em.close();
        }
    }

    @Override
    public DanhMucSanPham findById(int id) {
        EntityManager em = getEntityManager();
        try {
            return em.find(DanhMucSanPham.class, id);
        } finally {
            em.close();
        }
    }

    @Override
    public boolean insert(DanhMucSanPham category) {
        EntityManager em = getEntityManager();
        EntityTransaction trans = em.getTransaction();
        try {
            trans.begin();
            em.persist(category);
            trans.commit();
            return true;
        } catch (Exception e) {
            if (trans.isActive()) {
                trans.rollback();
            }
            e.printStackTrace();
            return false;
        } finally {
            em.close();
        }
    }

    @Override
    public boolean update(DanhMucSanPham category) {
        EntityManager em = getEntityManager();
        EntityTransaction trans = em.getTransaction();
        try {
            trans.begin();
            em.merge(category);
            trans.commit();
            return true;
        } catch (Exception e) {
            if (trans.isActive()) {
                trans.rollback();
            }
            e.printStackTrace();
            return false;
        } finally {
            em.close();
        }
    }

    @Override
    public boolean delete(int id) {
        EntityManager em = getEntityManager();
        EntityTransaction trans = em.getTransaction();
        try {
            trans.begin();
            DanhMucSanPham category = em.find(DanhMucSanPham.class, id);
            if (category != null) {
                em.remove(category);
            }
            trans.commit();
            return true;
        } catch (Exception e) {
            if (trans.isActive()) {
                trans.rollback();
            }
            e.printStackTrace();
            return false;
        } finally {
            em.close();
        }
    }
}
