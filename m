From: Raz Ben Yehuda <raz.benyehuda@mobileye.com>
Date: Wed, 17 Jun 2026 12:26:17 +0300
Subject: [PATCH v5 5/5] ufs: wmb is not implemented in x86.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260617-ufs_tool2-v5-5-1cf099f71111@mobileye.com>
References: <20260617-ufs_tool2-v5-0-1cf099f71111@mobileye.com>
In-Reply-To: <20260617-ufs_tool2-v5-0-1cf099f71111@mobileye.com>
To: u-boot@lists.denx.de
Cc: Neil Armstrong <neil.armstrong@linaro.org>, 
 Bhupesh Sharma <bhupesh.linux@gmail.com>, 
 Neha Malcom Francis <n-francis@ti.com>, 
 Tawfik Bayouk <tawfik.bayouk@mobileye.com>, 
 Vladimir Kondratiev <vladimir.Kondratiev@mobileye.com>, 
 Raz Ben Yehuda <raz.benyehuda@mobileye.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=792;
 i=raz.benyehuda@mobileye.com; h=from:subject:message-id;
 bh=nydWn0gbQOIFrfZq/h+hyYVuDb3OiJ5/WINnvK7yB10=;
 b=owEBbQKS/ZANAwAKAZ+a6ZSW6I45AcsmYgBqMmhFTjU3xeXkx5bGDyGSkG1yrF0Ne4feL0hQx
 29PWv4jbvKJAjMEAAEKAB0WIQSC7lz5E3UmOrJvRDqfmumUluiOOQUCajJoRQAKCRCfmumUluiO
 OULPEAChE1dNCMnJXxsX2yKpeGZ8RlDs/drD90ChrsOi6eP2tM/KiqoFF89OkcEbCyAO6UbrzMd
 vlSndOP6aOBcyDEZhi3/5cD9QtHHHkmrZrrlUj0/NQuYRdRJeDdbWU4cQ1UopCZcYDFR63xYpVI
 +HSD5mzBKLsZILC0fqZwU644BLFfJUc42fag1Cnj0g4HFWKZZGNvVjDT+28oQMIvVm1PmWRgg/J
 2uQbYT+Bt/xxrKzlG+J91qQnG4Si10jHepao5m68pIDO5aFGFdaT26slWS6b0KPXREOfxgh/aJt
 JcSlc9LswEPrt8CpMNpq6QqgNyiMHV+pPLG6QZusWVgsAfmLJe0N0XiPCPJUOjvc7HSaZqr+pcK
 kTi2JfqfipA4eUevsyge1+oVfbFDWq9MDSGKD3UKnrrVEbMG5diebgtf45g1HlyH/mWIy1bRAGz
 e97Z0sFJBxnyulcxAfNIXYAA6AVhlh6gkHPb1Y7mgun9fz2W4irDr5704/091tP6gWSEQTuJWSs
 TB64GDLHXPYra40M0lhIcMGIU8EtHHw4rJymgUKbL5jeWBMG8A+gLxZIUZHp4Gcdr7ia4qVaAbc
 gaMMR/LvEW9ME4vT4qqRG5zU7xU5HlrkaHgoJ+WxjHPMiiJw+32Arnh7L8xuEoSDFzo0TWyIkK9
 Nlxu4uC5inWWJqg==
X-Developer-Key: i=raz.benyehuda@mobileye.com; a=openpgp;
 fpr=82EE5CF91375263AB26F443A9F9AE99496E88E39
X-Endpoint-Received: by B4 Relay for raz.benyehuda@mobileye.com/default with auth_id=808
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

sfence: All stores (writes) issued before the fence become
globally visible before any store issued after the fence
memory: Compiler barrier

Signed-off-by: Raz Ben Yehuda <raz.benyehuda@mobileye.com>
---
 arch/x86/include/asm/io.h | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/arch/x86/include/asm/io.h b/arch/x86/include/asm/io.h
index 1390193f09c..9293588c9d7 100644
--- a/arch/x86/include/asm/io.h
+++ b/arch/x86/include/asm/io.h
@@ -241,6 +241,8 @@ static inline void sync(void)
  */
 #define dmb()		__asm__ __volatile__ ("" : : : "memory")
 #define mb()		__asm__ __volatile__ ("mfence" : : : "memory")
+#define wmb()		__asm__ __volatile__ ("sfence" ::: "memory") /* store mem barrier */
+
 #define __iormb()	dmb()
 #define __iowmb()	dmb()
 

-- 
2.43.0

