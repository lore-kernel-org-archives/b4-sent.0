From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Wed, 08 Jan 2025 19:09:27 +0530
Subject: [PATCH 1/2] bus: mhi: host: pci_generic: Use
 pci_try_reset_function() to avoid deadlock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250108-mhi_recovery_fix-v1-1-a0a00a17da46@linaro.org>
References: <20250108-mhi_recovery_fix-v1-0-a0a00a17da46@linaro.org>
In-Reply-To: <20250108-mhi_recovery_fix-v1-0-a0a00a17da46@linaro.org>
To: mhi@lists.linux.dev, Loic Poulain <loic.poulain@linaro.org>
Cc: Johan Hovold <johan@kernel.org>, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=2538;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=Beg2AFqZZL1RvTLG/5NUS0TciFZs05fGK2znhT/Ie3c=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBnfoARZYSvqd01mNXvbQZs16URxmMs7KFVOxBcu
 k5JZ8d4KkiJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZ36AEQAKCRBVnxHm/pHO
 9aL2B/0agETOOAhfKtVOGUJeWXPJTbpwzbpPvVW2MNAxK0FhkcReUe8GZHeT9g3iqAApqy+tMnb
 RYHf4dadmOJzNAHCTs11bBPBmhULknnnY3l7+kw9x1vTk433ree5DG4HAsbYQPeYGFvc1Iye7rt
 LR3tdZmhg80LLdNt0lnrXS1HZsm7aLEkdIU0/xlvqDe2qqUhG8m52t6sRVs/1dXnnON7qyhQyrH
 HPnKk220v7onEXWuxOFhwk7CDzNmbsLTcS0mKNtXi7ZfYfy1mQpOHLr5jxUXES+CJFI3jYqLLx4
 oF0Uz48INYGVlX4Pg0C5OX/xDMhfH6FT/RbCH6qxdUosr1bP
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There are multiple places from where the recovery work gets scheduled
asynchronously. Also, there are multiple places where the caller waits
synchronously for the recovery to be completed. One such place is during
the PM shutdown() callback.

If the device is not alive during recovery_work, it will try to reset the
device using pci_reset_function(). This function internally will take the
device_lock() first before resetting the device. By this time, if the lock
has already been acquired, then recovery_work will get stalled while
waiting for the lock. And if the lock was already acquired by the caller
which waits for the recovery_work to be completed, it will lead to
deadlock.

This is what happened on the X1E80100 CRD device when the device died
before shutdown() callback. Driver core calls the driver's shutdown()
callback while holding the device_lock() leading to deadlock.

And this deadlock scenario can occur on other paths as well, like during
the PM suspend() callback, where the driver core would hold the
device_lock() before calling driver's suspend() callback. And if the
recovery_work was already started, it could lead to deadlock. This is also
observed on the X1E80100 CRD.

So to fix both issues, use pci_try_reset_function() in recovery_work. This
function first checks for the availability of the device_lock() before
trying to reset the device. If the lock is available, it will acquire it
and reset the device. Otherwise, it will return -EAGAIN. If that happens,
recovery_work will fail with the error message "Recovery failed" as not
much could be done.

Cc: stable@vger.kernel.org # 5.12
Reported-by: Johan Hovold <johan@kernel.org>
Closes: https://lore.kernel.org/mhi/Z1me8iaK7cwgjL92@hovoldconsulting.com
Fixes: 7389337f0a78 ("mhi: pci_generic: Add suspend/resume/recovery procedure")
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 drivers/bus/mhi/host/pci_generic.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/bus/mhi/host/pci_generic.c b/drivers/bus/mhi/host/pci_generic.c
index 07645ce2119a..e92df380c785 100644
--- a/drivers/bus/mhi/host/pci_generic.c
+++ b/drivers/bus/mhi/host/pci_generic.c
@@ -1040,7 +1040,7 @@ static void mhi_pci_recovery_work(struct work_struct *work)
 err_unprepare:
 	mhi_unprepare_after_power_down(mhi_cntrl);
 err_try_reset:
-	if (pci_reset_function(pdev))
+	if (pci_try_reset_function(pdev))
 		dev_err(&pdev->dev, "Recovery failed\n");
 }
 

-- 
2.25.1

