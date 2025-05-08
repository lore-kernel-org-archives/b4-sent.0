From: Aaron Kling <webgeek1234@gmail.com>
Date: Wed, 07 May 2025 22:25:52 -0500
Subject: [PATCH v6 1/3] irqdomain: Export irq_domain_free_irqs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250507-pci-tegra-module-v6-1-5fe363eaa302@gmail.com>
References: <20250507-pci-tegra-module-v6-0-5fe363eaa302@gmail.com>
In-Reply-To: <20250507-pci-tegra-module-v6-0-5fe363eaa302@gmail.com>
To: Thomas Gleixner <tglx@linutronix.de>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kw@linux.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@linaro.org>
Cc: linux-kernel@vger.kernel.org, linux-pci@vger.kernel.org, 
 linux-tegra@vger.kernel.org, linux-pm@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746674753; l=813;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=HMpL5ZC0u0zHUx7X6iaMy1A5L01kC5VZDDTCKB3qS7U=;
 b=yNLWjKrlPioYJb28O/Qirs4sZiLKKFoYgaQMQj2YGLEysic2Q97uljDn0Hz1TEQFsIXL7JwIi
 BVmBC/xy6ArANd+VC9d+jaqJ6Md+HkTrVNMWbmepYZqEBxNMvF/mY7X
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Export irq_domain_free_irqs() to allow PCI/MSI drivers like pci-tegra to
be built as a module.

Reviewed-by: Thomas Gleixner <tglx@linutronix.de>
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 kernel/irq/irqdomain.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/kernel/irq/irqdomain.c b/kernel/irq/irqdomain.c
index ec6d8e72d980f604ded2bfa2143420e0e0095920..36cd79a8a2ce960b07b03c40067343ec8f632452 100644
--- a/kernel/irq/irqdomain.c
+++ b/kernel/irq/irqdomain.c
@@ -1890,6 +1890,7 @@ void irq_domain_free_irqs(unsigned int virq, unsigned int nr_irqs)
 	irq_domain_free_irq_data(virq, nr_irqs);
 	irq_free_descs(virq, nr_irqs);
 }
+EXPORT_SYMBOL_GPL(irq_domain_free_irqs);
 
 static void irq_domain_free_one_irq(struct irq_domain *domain, unsigned int virq)
 {

-- 
2.48.1

