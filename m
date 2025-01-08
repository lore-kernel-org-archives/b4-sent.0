From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Wed, 08 Jan 2025 19:09:28 +0530
Subject: [PATCH 2/2] bus: mhi: host: pci_generic: Recover the device
 synchronously from mhi_pci_runtime_resume()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250108-mhi_recovery_fix-v1-2-a0a00a17da46@linaro.org>
References: <20250108-mhi_recovery_fix-v1-0-a0a00a17da46@linaro.org>
In-Reply-To: <20250108-mhi_recovery_fix-v1-0-a0a00a17da46@linaro.org>
To: mhi@lists.linux.dev, Loic Poulain <loic.poulain@linaro.org>
Cc: Johan Hovold <johan@kernel.org>, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=3728;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=PbUVuYWUfqmustC2WiHHQap1G0eBPYmJC2LfYKutaU8=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBnfoAR34yGYQF9ycq3TNgC1rXfy1K3VN1q2TEbX
 bZuU9qbRAuJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZ36AEQAKCRBVnxHm/pHO
 9dAqB/49P68aL4DjPjADl5s3uTq/Fv4ZvUlOBpNpEAB3hxBsN5sU9I4NLNghM7SWTeWw7zQVb5s
 iz2A2ROGdhVQZj5E7awq6zDUIR+xMsm4TCet1Z/jsrbs6wcX7GDOFCptJq/wNzJHyEW4EnvuXmt
 9SW8Lc9aM+bDif5e3yn5jTal4/Q7tQh7/MjK3mYT1Bif09i9+H9jImoK0n0H6/fyWLvIPfMIpHO
 kmIf9OXb8+d9R7+q28oDVQxCCFHUBAo/ARtQDN8w1j5eMff9TdpB1fOQ7CvXXj4AwGC7uY528XL
 V0OtkzTkawrMyxuqfeXM4KTp4fhfhNbKJh53fWyEan0Y1epI
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently, in mhi_pci_runtime_resume(), if the resume fails, recovery_work
is started asynchronously and success is returned. But this doesn't align
with what PM core expects as documented in
Documentation/power/runtime_pm.rst:

"Once the subsystem-level resume callback (or the driver resume callback,
if invoked directly) has completed successfully, the PM core regards the
device as fully operational, which means that the device _must_ be able to
complete I/O operations as needed.  The runtime PM status of the device is
then 'active'."

So the PM core ends up marking the runtime PM status of the device as
'active', even though the device is not able to handle the I/O operations.
This same condition more or less applies to system resume as well.

So to avoid this ambiguity, try to recover the device synchronously from
mhi_pci_runtime_resume() and return the actual error code in the case of
recovery failure.

For doing so, move the recovery code to __mhi_pci_recovery_work() helper
and call that from both mhi_pci_recovery_work() and
mhi_pci_runtime_resume(). Former still ignores the return value, while the
latter passes it to PM core.

Cc: stable@vger.kernel.org # 5.13
Reported-by: Johan Hovold <johan@kernel.org>
Closes: https://lore.kernel.org/mhi/Z2PbEPYpqFfrLSJi@hovoldconsulting.com
Fixes: d3800c1dce24 ("bus: mhi: pci_generic: Add support for runtime PM")
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 drivers/bus/mhi/host/pci_generic.c | 29 +++++++++++++++++------------
 1 file changed, 17 insertions(+), 12 deletions(-)

diff --git a/drivers/bus/mhi/host/pci_generic.c b/drivers/bus/mhi/host/pci_generic.c
index e92df380c785..f6de407e077e 100644
--- a/drivers/bus/mhi/host/pci_generic.c
+++ b/drivers/bus/mhi/host/pci_generic.c
@@ -997,10 +997,8 @@ static void mhi_pci_runtime_put(struct mhi_controller *mhi_cntrl)
 	pm_runtime_put(mhi_cntrl->cntrl_dev);
 }
 
-static void mhi_pci_recovery_work(struct work_struct *work)
+static int __mhi_pci_recovery_work(struct mhi_pci_device *mhi_pdev)
 {
-	struct mhi_pci_device *mhi_pdev = container_of(work, struct mhi_pci_device,
-						       recovery_work);
 	struct mhi_controller *mhi_cntrl = &mhi_pdev->mhi_cntrl;
 	struct pci_dev *pdev = to_pci_dev(mhi_cntrl->cntrl_dev);
 	int err;
@@ -1035,13 +1033,25 @@ static void mhi_pci_recovery_work(struct work_struct *work)
 
 	set_bit(MHI_PCI_DEV_STARTED, &mhi_pdev->status);
 	mod_timer(&mhi_pdev->health_check_timer, jiffies + HEALTH_CHECK_PERIOD);
-	return;
+
+	return 0;
 
 err_unprepare:
 	mhi_unprepare_after_power_down(mhi_cntrl);
 err_try_reset:
-	if (pci_try_reset_function(pdev))
+	err = pci_try_reset_function(pdev);
+	if (err)
 		dev_err(&pdev->dev, "Recovery failed\n");
+
+	return err;
+}
+
+static void mhi_pci_recovery_work(struct work_struct *work)
+{
+	struct mhi_pci_device *mhi_pdev = container_of(work, struct mhi_pci_device,
+						       recovery_work);
+
+	__mhi_pci_recovery_work(mhi_pdev);
 }
 
 static void health_check(struct timer_list *t)
@@ -1400,15 +1410,10 @@ static int __maybe_unused mhi_pci_runtime_resume(struct device *dev)
 	return 0;
 
 err_recovery:
-	/* Do not fail to not mess up our PCI device state, the device likely
-	 * lost power (d3cold) and we simply need to reset it from the recovery
-	 * procedure, trigger the recovery asynchronously to prevent system
-	 * suspend exit delaying.
-	 */
-	queue_work(system_long_wq, &mhi_pdev->recovery_work);
+	err = __mhi_pci_recovery_work(mhi_pdev);
 	pm_runtime_mark_last_busy(dev);
 
-	return 0;
+	return err;
 }
 
 static int  __maybe_unused mhi_pci_suspend(struct device *dev)

-- 
2.25.1

