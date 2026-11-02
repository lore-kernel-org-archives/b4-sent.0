From: Tjerk Kusters <tkusters@aweta.nl>
Subject: [PATCH net v4 0/2] igb: only strip the Rx timestamp header from
 the first buffer of a frame
Date: Mon, 02 Nov 2026 10:58:12 +0100
Message-Id: <20261102-igb-rx-ts-fix-v4-0-8785124c5d23@aweta.nl>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALRe6GoC/3WNTQ7CIBhEr9KwFkNBsHXlPYwLfr62GEMNINY0v
 bsUN42Jy5nMezOjAN5CQKdqRh6SDXZ0ORx2FdKDdD1ga3JGlFBBRN1i2yvsJxwD7uyEtTkS3nA
 AVguUmYeHXBffBTmI6Potw1PdQMfVtM4GG+Lo3+U10TL+c5AorrFhqjGCcC0FPcsXRLl396JOb
 ANT/guzDLetYtBJ0hgtN/CyLB98Gc3B/QAAAA==
X-Change-ID: 20260619-igb-rx-ts-fix-cd70585ee316
To: Tony Nguyen <anthony.l.nguyen@intel.com>, 
 Przemek Kitszel <przemyslaw.kitszel@intel.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Alexei Starovoitov <ast@kernel.org>, Daniel Borkmann <daniel@iogearbox.net>, 
 Jesper Dangaard Brouer <hawk@kernel.org>, 
 John Fastabend <john.fastabend@gmail.com>, 
 Stanislav Fomichev <sdf@fomichev.me>, 
 Sven Auhagen <sven.auhagen@voleatech.de>, 
 Richard Cochran <richardcochran@gmail.com>, 
 Kurt Kanzenbach <kurt@linutronix.de>
Cc: intel-wired-lan@lists.osuosl.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, bpf@vger.kernel.org, 
 Maciej Fijalkowski <maciej.fijalkowski@intel.com>, Paul Moses <p@1g4.org>, 
 stable@vger.kernel.org, Tjerk Kusters <tkusters@aweta.nl>, 
 Piotr Kwapulinski <piotr.kwapulinski@intel.com>, 
 Aleksandr Loktionov <aleksandr.loktionov@intel.com>, 
 Alexander Nowlin <alexander.nowlin@intel.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793616473; l=4574;
 i=tkusters@aweta.nl; s=20260619; h=from:subject:message-id;
 bh=V317TYBLwQ5WuNCyFF4RLDMHWynYiHCEBd2nD508LPI=;
 b=ryqI9RDn2jIBrVdv2VZ0VDC8gJhkzqTYx+tZ+sPo/GvZamUxOjOLhrxVtuZwgWWzZWNbzkepK
 yPQNoyJ5XEQDyZDQzBaN1EYLdx1gQ29UMd4z8BCbz+X4Cy5DrHzCYz2
X-Developer-Key: i=tkusters@aweta.nl; a=ed25519;
 pk=JYRpYQ3+LrphEabgnxcbiOUpwvNP8WDDMcLzz+cwKsk=
X-Endpoint-Received: by B4 Relay for tkusters@aweta.nl/20260619 with auth_id=831
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With Rx hardware timestamping enabled (e.g. by ptp4l), igb strips the
16-byte inline timestamp header from every Rx buffer of a frame instead
of only from the first one. A continuation buffer that starts with 8
zero bytes loses 16 bytes, so jumbo frames with zero payload arrive
short and are dropped.

v3 used skb == NULL to find the first buffer of a frame. The Sashiko
AI review pointed out that this does not hold when an XDP program
consumes the first buffer of a frame that spans several buffers, so v3
was sent back for rework.

The same question came up for igc. There, Maciej suggested not to track
frame boundaries in the data path, but to make sure that frames never
span several buffers while XDP is attached [1]. Paul Moses' igc v3 does
that [2]. This version follows the same approach for igb:

  1/2 limits the receive length (RLPML, or the PF pool's VMOLR with VFs)
      to the configured frame size while XDP is attached, and leaves
      room for the timestamp header in the XDP buffer size checks.
  2/2 is v3, unchanged in code, with a note that it relies on 1/2.
      The Reviewed-by and Tested-by tags of v3 are kept for that reason.

Not addressed here: the AF_XDP zero-copy Rx path. igb_clean_rx_irq_zc()
has the same unguarded strip, and with 2 KiB UMEM chunks the hardware
buffer is rounded down to 1 KiB, so frames span descriptors there. The
igc counterpart is Maciej's buffer-size patch in [2]. I do not use
AF_XDP and cannot test it, so I would prefer to leave that to someone
who can.

How to reproduce
----------------
Receiver with igb (eth0), peer with MTU 8228. hwstamp_ctl turns on Rx
timestamping with filter ALL, no ptp4l needed; this ping method is
taken from Paul's igc report. One host with two ports also works if
the sending port is moved into its own network namespace.

1) Truncated jumbo frames (patch 2)

  receiver:  ip link set eth0 mtu 8228
             hwstamp_ctl -i eth0 -r 1
  peer:      ping -c 5 -M do -s 8200 -p 00 <receiver>

  Without the series there are no replies, and IpExtInTruncatedPkts
  goes up by one per frame. With the series all requests are answered.

2) XDP consumes the first buffer (patch 1)

  receiver:  ip link set eth0 mtu 3000
             hwstamp_ctl -i eth0 -r 1
             xdp-filter load -m native eth0
             xdp-filter ip <peer> -m src
             tcpdump -nn -e -i eth0 'ether src 00:00:00:00:00:00'
  peer:      ping -c 3 -M do -s 8200 -p 00 <receiver>

  At MTU 3000 XDP can attach, but without patch 1 the MAC still accepts
  the 8242-byte frames, which then span three Rx buffers. xdp-filter
  drops the first one, and the rest reaches the stack as a separate
  frame with all-zero MAC addresses:

    without the series    5154 bytes (header stripped twice)
    v3 alone              5170 bytes (stripped once)
    this series           no frame; rx_long_length_errors +1 per frame

Tested on an I350, kernel 6.14.9 with these patches, with the steps
above: results as listed. The v3 line is from an earlier run with an
XDP program dropping ICMP. Also checked: XDP attach at MTU 3030 works,
at MTU 3046 it is refused, as is an MTU change to 3046 with XDP
attached. With two VFs allocated (booted with pci=realloc), step 2
gives the same picture: three leftover frames without the series, none
with it, as the PF pool limit in VMOLR drops the frames.
Not tested: PAGE_SIZE >= 8192.

The patches, their descriptions and this cover letter were prepared
with the help of an AI coding assistant (Claude). I reviewed them and
ran the tests above on my test bench.

[1] https://lore.kernel.org/all/20261025065154.2037149-1-p@1g4.org/
[2] https://lore.kernel.org/all/20261028083344.3047350-1-p@1g4.org/

Changes in v4:
- New patch 1: limit the receive length while XDP is attached, so that
  skb == NULL reliably marks the first buffer (Sashiko review), as
  done for igc.
- Patch 2: no code change; added a note that it relies on patch 1.
- Link to v3: https://patch.msgid.link/20260625-igb-rx-ts-fix-v3-1-99b3efa08dca@aweta.nl

---
Tjerk Kusters (2):
      igb: do not let XDP frames span more than one Rx buffer
      igb: only strip Rx timestamp header on the first buffer of a frame

 drivers/net/ethernet/intel/igb/igb_main.c | 37 ++++++++++++++++++++++---------
 1 file changed, 26 insertions(+), 11 deletions(-)
---
base-commit: 2d3090a8aeb596a26935db0955d46c9a5db5c6ce
change-id: 20260619-igb-rx-ts-fix-cd70585ee316

Best regards,
--  
Tjerk Kusters <tkusters@aweta.nl>

