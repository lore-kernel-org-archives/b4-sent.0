From: Aaron Kling <webgeek1234@gmail.com>
Date: Sun, 20 Apr 2025 21:59:05 -0500
Subject: [PATCH 1/2] irqdomain: Export irq_domain_free_irqs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250420-pci-tegra-module-v1-1-c0a1f831354a@gmail.com>
References: <20250420-pci-tegra-module-v1-0-c0a1f831354a@gmail.com>
In-Reply-To: <20250420-pci-tegra-module-v1-0-c0a1f831354a@gmail.com>
To: Thomas Gleixner <tglx@linutronix.de>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kw@linux.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-kernel@vger.kernel.org, linux-pci@vger.kernel.org, 
 linux-tegra@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745204358; l=788;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=WmKEd3TO9tPKzFNggls+Iy5PtWJNMd2mTPJMCu0pPuI=;
 b=bGxGzNcIrwMZ0D+7pyP9QrXvMWdT+tYHR0Ciql7ZceIOyH3wcuRC8uh5pCIH3/gAWV63nJQsk
 KkO8PIXiUJCAXTOXbPKH1RlmjzxVDHEyAa9VP0+w5TGHyVQ1LCVCDCQ
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add export for irq_domain_free_irqs() so that we can allow drivers like
the pci-tegra driver to be loadable as a module.

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

