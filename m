From: Dickson Wu <dickson.wu@certik.com>
Subject: [PATCH 6.6.y 0/3] usb: typec: qcom-pmic-typec: fix late probe and
 debounce teardown
Date: Fri, 27 Nov 2026 20:47:00 +0000
Message-Id: <20261127-typec-66b-v1-0-6fe3a0983e5e@certik.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAETsCWsC/z2MywrCMBAAf6Xs2a1JhAT8FfGQx9ZGJCnZKJbSf
 zdR8DjDMBswlUgM52GDQq/IMacG8jCAn226EcbQGJRQWkplsK4LedTa4ckIZ4SYTPAErV8KTfH
 9fV1Aj3pc4frT/HR38rV/eugsE7pik5+7Ykqh5vzA7o//P+z7B8NmSj2eAAAA
X-Change-ID: 20261127-typec-66b-370b700f7dce
In-Reply-To: <2026090807-unbalance-starlet-1c55@gregkh>
References: <2026090807-unbalance-starlet-1c55@gregkh>
To: stable@vger.kernel.org
Cc: Fan Wu <fanwu01@zju.edu.cn>, Johan Hovold <johan+linaro@kernel.org>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 linux-usb@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795812420; l=1871;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=KbCi70Il9pHN83uuGT+W9IodsOWuIbZFQi3JcBLLZ54=;
 b=qFeFeZzyk8L23BGi8ucRQK5g1wBLbLqCpDmKE/59tgaWhwU0GJP+f8ykG+1vWTpeLKCDX6jOS
 vYTWvFner1fChgu2njaPA8n18v95qxMRhWBekbE5O6LBRyXrUPAdQfU
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Patch 1 unwinds port startup and TCPM registration on late probe errors.
Patch 2 blocks new CC debounce work and drains pending work on port stop.
Patch 3 does the same if port startup fails before the IRQs are enabled.
The two debounce fixes failed to apply to 6.6 in
<2026090807-unbalance-starlet-1c55@gregkh> and
<2026090836-sublet-submersed-cfc4@gregkh>.

The late-probe patch uses a newer driver layout. On 6.6 the unwind
calls the port helpers directly and keeps fwnode_handle_put().
This branch lacks disable_delayed_work_sync(), so port stop and
port-start failure block new debounce work under the port lock
and cancel pending work synchronously.

Tested on v6.6.163:
- The three patches applied cleanly with git am.
- Base and patched x86_64 allmodconfig W=1 builds passed for
  qcom_pmic_typec.o and qcom_pmic_typec_port.o with identical diagnostics.
- The patched x86_64 kernel booted under QEMU/KVM with
  CONFIG_TYPEC_QCOM_PMIC=y and powered down normally.
The guest has no Qualcomm PMIC, so the error and teardown paths were
checked in source only.

The backport and the test runs were prepared with AI coding tools
(OpenAI Codex agents, with review by Claude). I went over the result
before signing off.

---
Fan Wu (2):
      usb: typec: qcom-pmic-typec: disable cc_debounce_dwork on stop
      usb: typec: qcom-pmic-typec: drain cc_debounce_dwork if port_start() fails

Johan Hovold (1):
      usb: typec: qcom-pmic: fix use-after-free on late probe errors

 drivers/usb/typec/tcpm/qcom/qcom_pmic_typec.c      |  8 ++++++--
 drivers/usb/typec/tcpm/qcom/qcom_pmic_typec_port.c | 20 ++++++++++++++++++++
 2 files changed, 26 insertions(+), 2 deletions(-)
---
base-commit: e2bb30811e063ce0db964484357973b855b06572
change-id: 20261127-typec-66b-370b700f7dce

Best regards,
--  
Dickson Wu <dickson.wu@certik.com>

