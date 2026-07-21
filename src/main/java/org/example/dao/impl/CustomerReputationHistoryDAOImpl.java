package org.example.dao.impl;

import org.example.dao.CustomerReputationHistoryDAO;
import org.example.model.CustomerReputationHistory;
import org.example.util.JPAUtil;

import jakarta.persistence.EntityManager;

import java.util.List;

public class CustomerReputationHistoryDAOImpl implements CustomerReputationHistoryDAO {

    @Override
    public List<CustomerReputationHistory> getByAccountId(int accountId) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            return em.createQuery(
                    "SELECT h FROM CustomerReputationHistory h WHERE h.accountId = :accountId ORDER BY h.createdAt DESC",
                    CustomerReputationHistory.class)
                    .setParameter("accountId", accountId)
                    .getResultList();
        } finally {
            em.close();
        }
    }
}
