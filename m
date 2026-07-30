From: Mayank Rungta <mrungta@google.com>
Date: Thu, 30 Jul 2026 14:32:48 -0700
Subject: [PATCH 2/3] genirq: Export NMI APIs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260730-qcom-wdt-nmi-series-v1-2-3aa86d162914@google.com>
References: <20260730-qcom-wdt-nmi-series-v1-0-3aa86d162914@google.com>
In-Reply-To: <20260730-qcom-wdt-nmi-series-v1-0-3aa86d162914@google.com>
To: Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Thomas Gleixner <tglx@kernel.org>
Cc: linux-watchdog@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, "Kirill A. Shutemov" <kas@kernel.org>, 
 Douglas Anderson <dianders@chromium.org>, 
 Mayank Rungta <mrungta@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785447181; l=1464;
 i=mrungta@google.com; s=20260212; h=from:subject:message-id;
 bh=rdW88WNWcCzQEMOzt9UqoD+4nGwHea4B7drgBd3eHzU=;
 b=3/hZMpOPEiZ5AgoGkMS7xLaW0yXKNd2LDLMcEOXBpzSUTCs92XAcKOlhVpgR0C6pNiERQ1T0W
 vtfwKHZuM49BWOjMyvs58IuE3bJdpxbH/LQjAaRS7D7j/wWGmIJ4eMG
X-Developer-Key: i=mrungta@google.com; a=ed25519;
 pk=2Bjwbv/ibL10QnyvK9G7DoKpffXy7z6+M4NawEYgYDI=
X-Endpoint-Received: by B4 Relay for mrungta@google.com/20260212 with auth_id=634
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently, request_nmi(), free_nmi(), enable_nmi() and disable_nmi_nosync()
are restricted to built-in kernel code because they are not exported to
loadable modules.

Export these APIs to allow loadable modules to register and manage NMIs.
This allows watchdog drivers configured as loadable modules to register
their bark interrupt as an NMI.

Signed-off-by: Mayank Rungta <mrungta@google.com>
---
 kernel/irq/manage.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/kernel/irq/manage.c b/kernel/irq/manage.c
index 2fbff2618a1e..fb0b8da32f4c 100644
--- a/kernel/irq/manage.c
+++ b/kernel/irq/manage.c
@@ -766,6 +766,7 @@ void disable_nmi_nosync(unsigned int irq)
 {
 	disable_irq_nosync(irq);
 }
+EXPORT_SYMBOL_GPL(disable_nmi_nosync);
 
 void __enable_irq(struct irq_desc *desc)
 {
@@ -833,6 +834,7 @@ void enable_nmi(unsigned int irq)
 {
 	enable_irq(irq);
 }
+EXPORT_SYMBOL_GPL(enable_nmi);
 
 static int set_irq_wake_real(unsigned int irq, unsigned int on)
 {
@@ -2080,6 +2082,7 @@ const void *free_nmi(unsigned int irq, void *dev_id)
 
 	return __cleanup_nmi(irq, desc);
 }
+EXPORT_SYMBOL_GPL(free_nmi);
 
 /**
  * request_threaded_irq - allocate an interrupt line
@@ -2342,6 +2345,7 @@ int request_nmi(unsigned int irq, irq_handler_t handler,
 
 	return retval;
 }
+EXPORT_SYMBOL_GPL(request_nmi);
 
 void enable_percpu_irq(unsigned int irq, unsigned int type)
 {

-- 
2.55.0.508.g3f0d502094-goog

