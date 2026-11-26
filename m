From: Fabricio Akio <fabricioakio@gmail.com>
Date: Wed, 25 Nov 2026 23:50:23 -0300
Subject: [PATCH] soc: qcom: smp2p: Reset the last values only when the
 remote restarted
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-smp2p-ssr-reset-v1-1-ed442ed77950@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXM0QqCQBBG4VeRuW7AHXKRXiW6cPW3RsiWGYtAf
 HfXuvwuzlnJYQqnS7WS4aOur7kgnCrqH918B+tQTFJLDEEa9meWzO7GBsfCsYnn1NUtUhAqVTa
 M+v0dr7e//Z0m9MuxoW3bAZY5wDRzAAAA
X-Change-ID: 20261125-smp2p-ssr-reset-6564ba08eb12
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Deepak Kumar Singh <deepak.singh@oss.qualcomm.com>, 
 Chris Lew <chris.lew@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Fabricio Akio <fabricioakio@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795661423; l=2678;
 i=fabricioakio@gmail.com; s=20260928; h=from:subject:message-id;
 bh=Q1U2Pn/P1zafs/QofbW7Fr6+lX5ctVwV3JDZo//cqlw=;
 b=fvQpswV/HFL8fUj6KP2gcsjHea7zGyKS1Mz8UbNpHenHk50qWSa9BJc/b7Q/mIkTGo/QR93Yz
 sfdHHbhs5EgA9MGXbnRBqUwdathOTYkjwdQVBGLvoqvwdH6nJ2uD2tI
X-Developer-Key: i=fabricioakio@gmail.com; a=ed25519;
 pk=TlMUT8bPI/ZQzp2q24BIQTb2qSx/jdUTBlGEXIRCm54=
X-Endpoint-Received: by B4 Relay for fabricioakio@gmail.com/20260928 with auth_id=1076
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Once the SSR ack feature is negotiated, qcom_smp2p_check_ssr() clears
last_value of every inbound entry on each interrupt. Every bit that is
set is then reported as a new rising edge whenever the remote signals
anything: on the SDM630 ADSP, stopping the DSP raises its ready and
handover interrupts again.

Clear the values only when a restart of the remote is detected.

Fixes: 42c4cf5d4828 ("soc: qcom: smp2p: Add support for smp2p v2")
Signed-off-by: Fabricio Akio <fabricioakio@gmail.com>
---
In v1 and v2 of the series that added the reset it ran only when a
restart was detected and the remote's version was above 1; v3 dropped
both conditions:
https://lore.kernel.org/r/20250923-smp2p-v1-2-2c045af73dac@oss.qualcomm.com
https://lore.kernel.org/r/20251103152929.2434911-3-deepak.singh@oss.qualcomm.com
https://lore.kernel.org/r/20260127-smp2pv2-v3-2-4060b859b1e2@oss.qualcomm.com

Tested on a Motorola Moto X4 (SDM630), whose board file is not in
mainline yet, on sdm660-mainline's 7.2 kernel, the same build with and
without this patch. Stopping the ADSP:

  without: smp2p_notify_in: smp2p-adsp: slave-kernel: status:0x86 val:0x86
  with:    smp2p_notify_in: smp2p-adsp: slave-kernel: status:0x80 val:0x86

Without it the ready and handover interrupts are counted again, and that
kernel, which predates bb7c5d6f5b41 ("remoteproc: qcom: q6v5: Make
handover IRQ one-shot"), logs "Handover signaled, but it already
happened". With it, every start of the ADSP after a stop or a crash
still traces "SSR detected" and raises ready.

The ADSP's smp2p item reports version 1. No version 2 remote was tested:
that such a remote's restart is still detected, so that the reset still
runs for it, is taken from the description of 42c4cf5d4828.
---
 drivers/soc/qcom/smp2p.c | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)

diff --git a/drivers/soc/qcom/smp2p.c b/drivers/soc/qcom/smp2p.c
index cf06a49149be..d7f7345104e0 100644
--- a/drivers/soc/qcom/smp2p.c
+++ b/drivers/soc/qcom/smp2p.c
@@ -194,13 +194,16 @@ static bool qcom_smp2p_check_ssr(struct qcom_smp2p *smp2p)
 
 	restart_done = in->flags & BIT(SMP2P_FLAGS_RESTART_DONE_BIT);
 	restart = restart_done != smp2p->ssr_ack;
+	if (!restart)
+		return false;
+
 	list_for_each_entry(entry, &smp2p->inbound, node) {
 		if (!entry->value)
 			continue;
 		entry->last_value = 0;
 	}
 
-	return restart;
+	return true;
 }
 
 static void qcom_smp2p_do_ssr_ack(struct qcom_smp2p *smp2p)

---
base-commit: 909ef7a9a30fa139e69e555e3606680f5cca7726
change-id: 20261125-smp2p-ssr-reset-6564ba08eb12

Best regards,
--  
Fabricio Akio <fabricioakio@gmail.com>

