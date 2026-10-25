From: Patrick Fischer <admin@tsv-stahl-riesa.de>
Subject: [PATCH 0/2] serial: tegra: Fix 32-bit overflows in the clock rate
 adjustment
Date: Sun, 25 Oct 2026 23:50:03 +0100
Message-Id: <20261025-upstream-serial-tegra-overflow-v1-0-267b5b7a79ee@tsv-stahl-riesa.de>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXNyw6CQAyF4VchXdtkGIy3VzEuKtPBGmRIO6AJ4
 d0ddPktzn8WMFZhg0u1gPIsJmkoqHcVtA8aOkYJxeCdP9TONziNlpXphduQeszcKWGaWWOf3rg
 /hSa4eKQYzlAio3KUz+/gevvbpvuT27xVYV2/5xV1CYIAAAA=
X-Change-ID: 20261023-upstream-serial-tegra-overflow-48d3d0f7afd9
To: Laxman Dewangan <ldewangan@nvidia.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, 
 Thierry Reding <thierry.reding@kernel.org>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: Shardar Shariff Md <smohammed@nvidia.com>, 
 Krishna Yarlagadda <kyarlagadda@nvidia.com>, 
 Svyatoslav Ryhel <clamor95@gmail.com>, linux-kernel@vger.kernel.org, 
 linux-serial@vger.kernel.org, linux-tegra@vger.kernel.org, 
 stable@vger.kernel.org, Patrick Fischer <admin@tsv-stahl-riesa.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792968614; l=2014;
 i=admin@tsv-stahl-riesa.de; s=20261020; h=from:subject:message-id;
 bh=6EwOpSqQKG4Eh41ZzqS8mdnou7ZQ+bwoEZb8R5Qxc/Y=;
 b=dOtxdFiyP5QQqFHMgbg5Yi29rC6fDt+1DPiL6e561nRFUU6GC7l7b1GuEiU2nixn8r2ZuZ5H7
 xQ7UgE/Z9r+Bu/PkHgJnoNc/fIyQYUed7VWa9qWjjNLCMTQoqjoUR+j
X-Developer-Key: i=admin@tsv-stahl-riesa.de; a=ed25519;
 pk=D+v6EloYcEY9PIUHFyTM5sqcGIU/fIXzLUdkR8vjAtk=
X-Endpoint-Received: by B4 Relay for admin@tsv-stahl-riesa.de/20261020 with auth_id=1251
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On 32-bit ARM, both the clock rate adjustment from
"nvidia,adjust-baud-rates" and the check of the resulting rate overflow
a 32-bit long at the high baud rates the adjustment is meant for. On
the Tegra Note 7 (Tegra114), Bluetooth at 3 Mbaud therefore ran with a
UART clock 5.6 % too low, and the check computed -0.18 % and let it
pass.

UART clock at 3 Mbaud with a tolerance of 136 for 1 to 4 Mbaud
(pll_p 408 MHz):

                    requested    configured   check
  without patches   47.79 MHz    45.33 MHz    -0.18 %
  with patches      48.65 MHz    48.00 MHz     0.00 %

With both patches and the unchanged tolerance of 136, Bluetooth on the
Tegra Note 7 works at 3 Mbaud: the UART clock is 48.00 MHz, and the
WL1801 scans and connects to a paired device without HCI errors.

With a deliberately wrong tolerance of -500, which gives 45.33 MHz at
3 Mbaud, the check now reports the deviation (out of range by -555,
i.e. -5.55 %) instead of letting it pass.

Both bugs date back to v5.4. 64-bit platforms are not affected.

Tool use (see Documentation/process/generated-content.rst): both
patches, their changelogs and this cover letter were prepared with an
LLM coding assistant (Claude Code), which traced the wrong clock rates
I measured on the device to the overflows, wrote the fixes and drafted
the texts. It also recalculated the old and new arithmetic for the
affected rates in a small userspace program; the results match the
rates measured on the device. I reviewed the changes and ran the tests
on the device.

---
Patrick Fischer (2):
      serial: tegra: Fix overflow in tegra_get_tolerance_rate()
      serial: tegra: Fix overflow in tegra_check_rate_in_range()

 drivers/tty/serial/serial-tegra.c | 9 +++++----
 1 file changed, 5 insertions(+), 4 deletions(-)
---
base-commit: 734bef548a96e8774d6eef5dfa2026c6edc4e80b
change-id: 20261023-upstream-serial-tegra-overflow-48d3d0f7afd9

Best regards,
--  
Patrick Fischer <admin@tsv-stahl-riesa.de>

