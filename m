From: Christian Taedcke <christian.taedcke@weidmueller.com>
Subject: [PATCH net 0/2] net: macb: fix TXUBR interrupt storm on link
 flapping
Date: Mon, 06 Jul 2026 16:02:13 +0200
Message-Id: <20260706-upstreaming-macb-irq-storm-v1-0-ab3115b5a13a@weidmueller.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGW1S2oC/yXMywrCMBBG4Vcps3YgTcHbq4iLpP2tIyStM6kIp
 e9u1OU5i28lgwqMzs1KipeYTLlGu2uov4c8gmWoTd75vTu4jpfZiiIkySOn0EcWfbKVSRMjDv7
 kYotj56kCs+Im7x9+oYxC1/+0JT7Qly9L2/YBE/amu4MAAAA=
X-Change-ID: 20260703-upstreaming-macb-irq-storm-ebd290b1e832
To: christian.taedcke-oss@weidmueller.com, 
 =?utf-8?q?Th=C3=A9o_Lebrun?= <theo.lebrun@bootlin.com>, 
 Conor Dooley <conor.dooley@microchip.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Kevin Hao <haokexin@gmail.com>, Simon Horman <horms@kernel.org>, 
 Sebastian Andrzej Siewior <bigeasy@linutronix.de>, 
 Clark Williams <clrkwllms@kernel.org>, Steven Rostedt <rostedt@goodmis.org>, 
 Robert Hancock <robert.hancock@calian.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-rt-devel@lists.linux.dev, 
 Christian Taedcke <christian.taedcke@weidmueller.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783346550; l=2123;
 i=christian.taedcke@weidmueller.com; s=20260702; h=from:subject:message-id;
 bh=LGjH+VaxkyRsmQ/os7WX5aNwBGmhH6HBNhqikwdceMM=;
 b=33b8wgskQBt3ZzGbeRbzLxtKAax+bkWySLpAMG4R44eStuzkCjtdwcSi2Xwcf8nNYvGetIncg
 4bsnHablbDDC8NMTCRGmWQO8UcGU8BkoraAFd4qw9AiKf8T3H1Q7YuZ
X-Developer-Key: i=christian.taedcke@weidmueller.com; a=ed25519;
 pk=fVCoBhFV3uMogA2nxIOU/rynNY+O2TDJgWvWjR06TrQ=
X-Endpoint-Received: by B4 Relay for christian.taedcke@weidmueller.com/20260702 with auth_id=847
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

We observed a hard interrupt storm in the Cadence GEM (macb) driver on
a Xilinx ZynqMP based platform running a PREEMPT_RT kernel (6.6.142).

After several Ethernet link up/down transitions, the CPU that the MAC
IRQ is pinned to is pegged at 100% in the threaded MAC interrupt
handler and the kernel reports "sched: RT throttling activated",
killing the network interface. The MAC ISR keeps refiring with the
level-triggered TXUBR (TX used bit read) set, because the transmitter
is left pointing at a descriptor whose used bit is set. See the
individual commit messages for the full analysis.

Patch 1 fixes the root cause: gem_shuffle_tx_one_ring() resets tx_tail to
the ring base on link-up but never reprograms the hardware TBQP pointer.

Patch 2 fixes a second, independent bug: macb_interrupt() masks only
TCOMP (not TXUBR) when scheduling the TX NAPI, and macb_tx_poll()
re-enables only TCOMP. Because TXUBR is level-triggered, a persistent
used-descriptor condition keeps it asserted and re-fires immediately,
storming the MAC interrupt.

Both patches are required: on the affected platform the interrupt storm
still reproduces with patch 1 applied alone, so patch 2 is needed as
well to stop it.

The relevant code is essentially identical in mainline, so the bug is not
RT-specific. PREEMPT_RT merely turns the storm into a fatal failure via
RT throttling.

Tested on ZynqMP with PREEMPT_RT by repeatedly flapping the Ethernet
link. The interrupt storm and RT throttling no longer occur.

Assisted-by: Claude:claude-opus-4-8
Signed-off-by: Christian Taedcke <christian.taedcke@weidmueller.com>
---
Christian Taedcke (2):
      net: macb: reprogram TBQP after shuffling the TX ring on link-up
      net: macb: mask TXUBR during TX NAPI poll to prevent IRQ storms

 drivers/net/ethernet/cadence/macb_main.c | 14 +++++++++++---
 1 file changed, 11 insertions(+), 3 deletions(-)
---
base-commit: dc59e4fea9d83f03bad6bddf3fa2e52491777482
change-id: 20260703-upstreaming-macb-irq-storm-ebd290b1e832

Best regards,
--  
Christian Taedcke <christian.taedcke@weidmueller.com>

