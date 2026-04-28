From: Max Boone <mboone@akamai.com>
Date: Tue, 28 Apr 2026 20:04:14 +0200
Subject: [PATCH RFC] net/mlx5: check whether VFs are assigned before
 disabling SR-IOV
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260428-mlx5-sriov-in-use-check-v1-1-c7b9e18c99a8@akamai.com>
X-B4-Tracking: v=1; b=H4sIAJ328GkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDEyML3dycClPd4qLM/DLdzDzd0uJU3eSM1ORsXdPkZKNEc0szY4tUUyW
 g7oKi1LTMCrDJ0UpBbs5KsbW1AJ6bm0JuAAAA
X-Change-ID: 20260428-mlx5-sriov-in-use-check-5cc2a79638e5
To: Saeed Mahameed <saeedm@nvidia.com>, Leon Romanovsky <leon@kernel.org>, 
 Tariq Toukan <tariqt@nvidia.com>, Mark Bloch <mbloch@nvidia.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-rdma@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Max Boone <mboone@akamai.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777399456; l=2829;
 i=mboone@akamai.com; s=20260317; h=from:subject:message-id;
 bh=mkoemVwnFGeOEz/ltYOEqOoOvjAbOxb3nCL6rP2fq0E=;
 b=qNoCEt363xktAl0UM2/HTfSVD15+he3s20EebK4zJcoEOpu59TRij4kCh+lLpVYSY5atEaNhv
 kWtbH5x890kBoEI1Sh6QFWpveUcp1GkIJIRsvpm7AxTX1Qy5UvVvxTP
X-Developer-Key: i=mboone@akamai.com; a=ed25519;
 pk=jWdC/h5H2KWQCiC2kpr/puMVX0mJmP9W5sM8YTGBXA4=
X-Endpoint-Received: by B4 Relay for mboone@akamai.com/20260317 with auth_id=685
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When MLX5 cards are passed through to a VM, disabling SR-IOV by
setting the sriov_numvfs to 0 will render the machine unstable.

Other drivers (such as ixgbe, bnxt and octep) add this check to
see whether the VFs are passed through to a VM.

Signed-off-by: Max Boone <mboone@akamai.com>
---
 drivers/net/ethernet/mellanox/mlx5/core/mlx5_core.h |  2 +-
 drivers/net/ethernet/mellanox/mlx5/core/sriov.c     | 11 +++++++++--
 2 files changed, 10 insertions(+), 3 deletions(-)

diff --git a/drivers/net/ethernet/mellanox/mlx5/core/mlx5_core.h b/drivers/net/ethernet/mellanox/mlx5/core/mlx5_core.h
index 1507e881d..85fe89c00 100644
--- a/drivers/net/ethernet/mellanox/mlx5/core/mlx5_core.h
+++ b/drivers/net/ethernet/mellanox/mlx5/core/mlx5_core.h
@@ -240,7 +240,7 @@ void mlx5_sriov_cleanup(struct mlx5_core_dev *dev);
 int mlx5_sriov_attach(struct mlx5_core_dev *dev);
 void mlx5_sriov_detach(struct mlx5_core_dev *dev);
 int mlx5_core_sriov_configure(struct pci_dev *dev, int num_vfs);
-void mlx5_sriov_disable(struct pci_dev *pdev, bool num_vf_change);
+int mlx5_sriov_disable(struct pci_dev *pdev, bool num_vf_change);
 int mlx5_core_sriov_set_msix_vec_count(struct pci_dev *vf, int msix_vec_count);
 int mlx5_core_enable_hca(struct mlx5_core_dev *dev, u16 func_id);
 int mlx5_core_disable_hca(struct mlx5_core_dev *dev, u16 func_id);
diff --git a/drivers/net/ethernet/mellanox/mlx5/core/sriov.c b/drivers/net/ethernet/mellanox/mlx5/core/sriov.c
index bf6f631cf..07c61a73b 100644
--- a/drivers/net/ethernet/mellanox/mlx5/core/sriov.c
+++ b/drivers/net/ethernet/mellanox/mlx5/core/sriov.c
@@ -200,16 +200,23 @@ static int mlx5_sriov_enable(struct pci_dev *pdev, int num_vfs)
 	return err;
 }
 
-void mlx5_sriov_disable(struct pci_dev *pdev, bool num_vf_change)
+int mlx5_sriov_disable(struct pci_dev *pdev, bool num_vf_change)
 {
 	struct mlx5_core_dev *dev  = pci_get_drvdata(pdev);
 	struct devlink *devlink = priv_to_devlink(dev);
 	int num_vfs = pci_num_vf(dev->pdev);
 
+	if (pci_vfs_assigned(dev->pdev)) {
+		mlx5_core_warn(dev, "can't disable sriov, VFs are assigned\n");
+		return -EPERM;
+	}
+
 	pci_disable_sriov(pdev);
 	devl_lock(devlink);
 	mlx5_device_disable_sriov(dev, num_vfs, true, num_vf_change);
 	devl_unlock(devlink);
+
+	return 0;
 }
 
 int mlx5_core_sriov_configure(struct pci_dev *pdev, int num_vfs)
@@ -223,7 +230,7 @@ int mlx5_core_sriov_configure(struct pci_dev *pdev, int num_vfs)
 	if (num_vfs)
 		err = mlx5_sriov_enable(pdev, num_vfs);
 	else
-		mlx5_sriov_disable(pdev, true);
+		err = mlx5_sriov_disable(pdev, true);
 
 	if (!err)
 		sriov->num_vfs = num_vfs;

---
base-commit: dca922e019dd758b4c1b4bec8f1d509efddeaab4
change-id: 20260428-mlx5-sriov-in-use-check-5cc2a79638e5

Best regards,
-- 
Max Boone <mboone@akamai.com>

