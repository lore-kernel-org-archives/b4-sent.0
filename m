From: Robin Snyders <robin@snyders.xyz>
Subject: [PATCH 0/3] power: supply: qcom_smbx: add SMB5 support
Date: Tue, 11 Aug 2026 22:35:03 +0200
Message-Id: <20260811-submit-qcom-smbx-send-v1-v1-0-feec6cfa123a@snyders.xyz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MTQ5AMBBA4avIrE1iLOrnKmJRNZhFiw4iEXfXW
 H6L9x5QjsIKbfZA5EtU1pBAeQZusWFmlDEZyqI0RU2Eeg5eDtzd6lH9cKNyGPEiNI11PFlDTVV
 ByrfIk9z/uuvf9wPxX9CBagAAAA==
X-Change-ID: 20260811-submit-qcom-smbx-send-v1-69acefa61977
To: Casey Connolly <casey.connolly@linaro.org>, 
 Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-pm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Robin Snyders <robin@snyders.xyz>, Joel Selvaraj <foss@joelselvaraj.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786480511; l=1365;
 i=robin@snyders.xyz; s=default; h=from:subject:message-id;
 bh=+P82h6mp+hEn0vn1HuUzgSXQCVwUZSASzPwY53+NlTo=;
 b=aIO8pm3D+uXsVtToEKvt+5xvyG+S4IRDgKKHi3c5cHvJ7yGWiCCJBwqoH+t1jaXy7iUiRsVQM
 /oYYMCuqvE0DavUIhYTL7LnjH5vLHIvUKdyxssVTDtlWcpMK8vFwrB4
X-Developer-Key: i=robin@snyders.xyz; a=ed25519;
 pk=Mdk5dNn+Tkcy7BWexDxBLR/s1BNz8WdqDPnr3qtYBIU=
X-Endpoint-Received: by B4 Relay for robin@snyders.xyz/default with auth_id=938
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for the SMB5 charger generation found in PM7250B and
PM8150B to the existing qcom_smbx driver.

The series extends the binding, selects register layouts and electrical
limits from per-PMIC match data, initializes SMB5 with charging and USB
input suspended, and programs a stable AICL rerun interval.

This was tested on a OnePlus 7T Pro (HD1913) with PM8150B. Register
reads confirmed 4.40 V, 1.50 A and 500 mA limits. A 180-second guarded
charging trace and a subsequent 600-second runtime trace completed
without crossing the voltage guard.

The driver was built with LLVM and the binding passed dt_binding_check.
All three patches pass checkpatch --strict.

Based on linux-next 20260810 (3d08ff75a47a).

Signed-off-by: Robin Snyders <robin@snyders.xyz>
---
Casey Connolly (3):
      dt-bindings: power: supply: qcom,pmi8998-charger: add SMB5 PMICs
      power: supply: qcom_smbx: add SMB5 support
      power: supply: qcom_smbx: program AICL rerun time

 .../power/supply/qcom,pmi8998-charger.yaml         |   2 +
 drivers/power/supply/qcom_smbx.c                   | 521 ++++++++++++++++++---
 2 files changed, 457 insertions(+), 66 deletions(-)
---
base-commit: 3d08ff75a47a3e7e2ab45a3bcab6723b4d906422
change-id: 20260811-submit-qcom-smbx-send-v1-69acefa61977

Best regards,
-- 
Robin Snyders <robin@snyders.xyz>

