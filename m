From: Janne Grunau <j@jannau.net>
Subject: [PATCH 0/2] Remove HID_LENOVO's dependency on ACPI
Date: Sun, 18 May 2025 12:18:36 +0200
Message-Id: <20250518-hid_lenovo_acpi_dependency-v1-0-afdb93b5d1a6@jannau.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPyzKWgC/x3MQQqDMBAF0KvIrA1E0Sq9SpEQM791oExCAtIi3
 t3g8m3eQQVZUOjZHJSxS5GoFV3bUNi8fmCEq6m3/WjHbjabsPtC4x6dD0kcI0EZGv7Gwk+zf6w
 8DZZqkDLe8rvz13KeF+s/Ge5sAAAA
X-Change-ID: 20250518-hid_lenovo_acpi_dependency-0ea78a6bd740
To: Arnd Bergmann <arnd@arndb.de>, Jiri Kosina <jikos@kernel.org>, 
 Benjamin Tissoires <bentiss@kernel.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Len Brown <lenb@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-input@vger.kernel.org, 
 linux-acpi@vger.kernel.org, Janne Grunau <j@jannau.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1170; i=j@jannau.net;
 s=yk2024; h=from:subject:message-id;
 bh=f8yNvFacwIT2UBvCLLpHpjc6kqW1QOVGmRxfY131Q44=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhgzNzf9nn8pcwrEx+YZ9/J7D39Qvm7DuSyialmX9/pqNW
 wHvrN8MHaUsDGJcDLJiiixJ2i87GFbXKMbUPgiDmcPKBDKEgYtTACYidIvhf8iEzxPDtd7ll3ia
 HrA+/OS67fWXM1dGfNZ572LYJMDncIORYfOfynuyR66wJsZ3RfllBM+x/PzXZPmcqSxZbXobjv8
 NYgEA
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/yk2024 with auth_id=264
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

hid-lenovo supports external generic USB and Bluetooth devices and
should be buildable and usable on non-ACPI kernels and systems. Commit
84c9d2a968c82 ("HID: lenovo: Support for ThinkPad-X12-TAB-1/2 Kbd Fn
keys") added a hot key to cycle through power profiles using ACPI's
platform_profile. This resulted in adding a dependency on ACPI and
selecting CONFIG_ACPI_PLATFORM_PROFILE to fix build an link errors in
commit 52572cde8b4a ("HID: lenovo: select
CONFIG_ACPI_PLATFORM_PROFILE"). This is undesirable for HID drivers
supporting generic USB and Bluetooth devices. So instead stub the only
used function platform_profile_cycle() and relax the dependency.

Signed-off-by: Janne Grunau <j@jannau.net>
---
Janne Grunau (2):
      ACPI: platform_profile: Stub platform_profile_cycle
      HID: lenovo: Remove CONFIG_ACPI dependency

 drivers/hid/Kconfig              |  4 ++--
 include/linux/platform_profile.h | 11 +++++++++++
 2 files changed, 13 insertions(+), 2 deletions(-)
---
base-commit: 0af2f6be1b4281385b618cb86ad946eded089ac8
change-id: 20250518-hid_lenovo_acpi_dependency-0ea78a6bd740

Best regards,
-- 
Janne Grunau <j@jannau.net>

