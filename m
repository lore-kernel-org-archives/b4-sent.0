From: Janne Grunau <j@jannau.net>
Date: Sun, 18 May 2025 12:18:37 +0200
Subject: [PATCH 1/2] ACPI: platform_profile: Stub platform_profile_cycle
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250518-hid_lenovo_acpi_dependency-v1-1-afdb93b5d1a6@jannau.net>
References: <20250518-hid_lenovo_acpi_dependency-v1-0-afdb93b5d1a6@jannau.net>
In-Reply-To: <20250518-hid_lenovo_acpi_dependency-v1-0-afdb93b5d1a6@jannau.net>
To: Arnd Bergmann <arnd@arndb.de>, Jiri Kosina <jikos@kernel.org>, 
 Benjamin Tissoires <bentiss@kernel.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Len Brown <lenb@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-input@vger.kernel.org, 
 linux-acpi@vger.kernel.org, Janne Grunau <j@jannau.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1409; i=j@jannau.net;
 s=yk2024; h=from:subject:message-id;
 bh=OlgPj4E6TaBNRe/5BROdqUQFmhB+Ec3RjhF6hKrPB94=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhgzNLQwMvefyyg6k51d8+nXzxaWpjaLL3963U9ziGrCYa
 9vn0NXiHaUsDGJcDLJiiixJ2i87GFbXKMbUPgiDmcPKBDaEi1MAJmJsxPC/Nmj9vTNGkdz9k5+k
 vrUzZLu3jbP4/HuLdat3axvdi/g/kZGhaR1v/oqd240U1GxmHutKFRdX5+S+eu7k68bre1czLDj
 ICwA=
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/yk2024 with auth_id=264
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is required to allow USB/Bluetooth HID devices to cycle through
platform profiles without depending on ACPI. Commit 52572cde8b4a4
("HID: lenovo: select CONFIG_ACPI_PLATFORM_PROFILE") added this
dependency for hid-lenovo which is used for external USB and Bluetooth
devices.

Fixes: 52572cde8b4a4 ("HID: lenovo: select CONFIG_ACPI_PLATFORM_PROFILE")
Signed-off-by: Janne Grunau <j@jannau.net>
---
 include/linux/platform_profile.h | 11 +++++++++++
 1 file changed, 11 insertions(+)

diff --git a/include/linux/platform_profile.h b/include/linux/platform_profile.h
index a299225ab92e78ce2e978b1774cdfc95cc688e8f..05a6749991601fd373683c3d498c6e9cc4f97882 100644
--- a/include/linux/platform_profile.h
+++ b/include/linux/platform_profile.h
@@ -54,7 +54,18 @@ void platform_profile_remove(struct device *dev);
 struct device *devm_platform_profile_register(struct device *dev, const char *name,
 					      void *drvdata,
 					      const struct platform_profile_ops *ops);
+#ifdef CONFIG_ACPI_PLATFORM_PROFILE
 int platform_profile_cycle(void);
+#else
+/*
+ * This stub is needed to allow USB/Bluetooth HID drivers to cycle through
+ * platform profiles.
+ */
+static inline int platform_profile_cycle(void)
+{
+	return 0;
+}
+#endif /* CONFIG_ACPI_PLATFORM_PROFILE */
 void platform_profile_notify(struct device *dev);
 
 #endif  /*_PLATFORM_PROFILE_H_*/

-- 
2.49.0

