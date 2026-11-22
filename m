From: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Subject: [PATCH v2 0/2] power: supply: qcom_battmgr: Apply the USB host
 current limit early
Date: Mon, 23 Nov 2026 00:50:14 +0530
Message-Id: <20261123-vantage-battmgr-v2-0-03a419078d0a@yahoo.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNQQ6DIBREr2L+ujSCArWr3qNxAfRXaKIYoKTGe
 PeiXXf5JjNvVogYHEa4VisEzC46PxVgpwqMVdOAxD0KA6uZoJQKktWUVIm1SmkcAulajoIJeWl
 MC2U1B3y6z2G89z+Ob/1Ck3bN3rAuJh+W4zLTvfffnimpidS8o1w2Ump5W5T1/mz8CP22bV/Aa
 rbCwAAAAA==
X-Change-ID: 20261116-vantage-battmgr-945e626783c4
To: Sebastian Reichel <sre@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-pm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Joonhoe Kim <26rote@gmail.com>, 
 phone-devel@vger.kernel.org, Venkat Yadlapati <venkat.yadlapati@yahoo.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795375214; l=1656;
 i=venkat.yadlapati@yahoo.com; s=20261023; h=from:subject:message-id;
 bh=GKw0fAYD2THqTePsaxcaYFmMb0GJeDBVUvNBjHIW/Zg=;
 b=SFJJnRpQGclZd2uAF7+00OqMR0H8exJbdBYTv4wTtGPq9oz3g+Qfb0P1eG7h3wqOMPHYu6oi6
 62Cy0HQIredBebnY/x60ou5Pok96vvKDly07nh+aAa5BDt7fQ/GlajY
X-Developer-Key: i=venkat.yadlapati@yahoo.com; a=ed25519;
 pk=e8KStCtEMvUP1Se/riB/KVnDAQFEVR2Dw2PcuA8/eME=
X-Endpoint-Received: by B4 Relay for venkat.yadlapati@yahoo.com/20261023 with auth_id=1303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On the Motorola Signature the battery manager firmware keeps the input
current limit of a USB host port at the 100 mA allowed before
enumeration, so the phone discharges while it is connected to a
computer. The dwc3 controller reports the current the host grants
through usb-psy-name, and commit be5e7367bceb made the limit writable.

The controller reports it before the battery manager service is up
though, so the first patch keeps the limit and applies it once the
service comes up. The second one applies it only to SDP, CDP and USB PD
ports, like the downstream driver, so a dedicated charger is never
throttled to what the controller reports.

Tested on a Motorola Signature: connected to a computer it charges after
enumeration instead of discharging.

I used an LLM (Claude) to help write these patches and their commit
messages. I reviewed all of them and tested the result on the device.

---
Changes in v2:
- Drop the Assisted-by trailers and the LLM notes from the commit
  messages, the LLM use is stated in this cover letter.
- Link to v1: https://patch.msgid.link/20261116-vantage-battmgr-v1-0-7b59157377b7@yahoo.com

---
Venkat Yadlapati (2):
      power: supply: qcom_battmgr: Apply a USB input current limit set early
      power: supply: qcom_battmgr: Don't limit the input current of chargers

 drivers/power/supply/qcom_battmgr.c | 61 ++++++++++++++++++++++++++++++++-----
 1 file changed, 53 insertions(+), 8 deletions(-)
---
base-commit: 7071d4750856abbc68dfe431acc58a1d45dd42e8
change-id: 20261116-vantage-battmgr-945e626783c4

Best regards,
--  
Venkat Yadlapati <venkat.yadlapati@yahoo.com>

