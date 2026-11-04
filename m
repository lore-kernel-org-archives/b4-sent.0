From: Tjerk Kusters <tkusters@aweta.nl>
Subject: [PATCH net v5 0/4] igb: only strip the Rx timestamp header from
 the first buffer of a frame
Date: Wed, 04 Nov 2026 07:40:01 +0100
Message-Id: <20261104-igb-rx-ts-fix-v5-0-bf4b4367129a@aweta.nl>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEHT6moC/3XNQQrCMBAF0KtI1o4kkyamrryHuEiTUSNSJYlVK
 b27aQWRgsv5/PenZ4lioMQ2i55F6kIK17Ycarlg7mTbI0Hw5WbIUXMtagjHBuITcoJDeILza66
 MIpJCs2JukUo87e1YS5ntP2G6N2dyeVwaa6eQ8jW+pq8dTuU/DzoEAV42xmuunNW4tQ/KdtVep
 ulO/mBUcywLrutG0sFy452d4eqLheA4xxVwMGujBFZOeZQ/eBiGN+mhMFg6AQAA
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
 Kurt Kanzenbach <kurt@linutronix.de>, 
 Sriram Yagnaraman <sriram.yagnaraman@ericsson.com>
Cc: intel-wired-lan@lists.osuosl.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, bpf@vger.kernel.org, 
 Maciej Fijalkowski <maciej.fijalkowski@intel.com>, Paul Moses <p@1g4.org>, 
 stable@vger.kernel.org, Tjerk Kusters <tkusters@aweta.nl>, 
 Piotr Kwapulinski <piotr.kwapulinski@intel.com>, 
 Aleksandr Loktionov <aleksandr.loktionov@intel.com>, 
 Alexander Nowlin <alexander.nowlin@intel.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793774404; l=9836;
 i=tkusters@aweta.nl; s=20260619; h=from:subject:message-id;
 bh=9/866LQ02ZvOFzui6lZ0yG5RWFsfpe/KbY1lgj33KiE=;
 b=8kaWM/zxNC57bs7QJKwJeKk9tWz0iUD79eBdACNVDrkBJz4NNVXpjzqzY265U8d3D3KFeCyaj
 DLQm9Ncm0PSD+P9025chIgbefN4IqH6FKoihMV8fWb+tWREu+NcScFL
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

  1/4 limits the receive length (RLPML, or the PF pool's VMOLR with VFs)
      to the configured frame size while XDP is attached, and leaves
      room for the timestamp header in the XDP buffer size checks for
      3 KiB, legacy-rx and PAGE_SIZE >= 8192 buffers. It also refuses
      XDP with rx-all and legacy-rx changes while XDP is attached, as
      both would break the limit. The limit is now set from
      igb_configure() instead of igb_set_rx_mode().
  2/4 is v3, unchanged in code, with a note that it relies on 1/4.
      The Reviewed-by and Tested-by tags of v3 are kept for that reason.
  3/4 gives AF_XDP zero-copy rings a 2 KiB or 3 KiB hardware buffer
      instead of rounding the XSK frame size down to 1 KiB. It refuses
      XSK pools that cannot hold the current maximum frame plus the
      timestamp header, and MTU changes that would no longer fit a bound
      pool. Unlike the igc patch in [2], which checks against the
      largest XDP MTU, this checks the current MTU, as igb allows XDP up
      to MTU 3030 and a fixed check would rule out 2 KiB chunks. A pool
      that does not fit when its queue is configured, for example after
      SR-IOV changed the queue count, is not used in zero-copy mode.
  4/4 drops zero-copy frames that still span several descriptors, as
      ixgbe does, instead of passing each buffer on as a frame. It
      depends on 3/4.

As in igc, 1/4 moves the RLPML programming out of igb_set_rx_mode(),
which can run without RTNL, into igb_configure(), which only runs while
Rx is stopped. This includes the PF pool limit in VMOLR, which
igb_set_rx_mode() now leaves as it is. Attaching or removing XDP on a
running interface goes through igb_close() and igb_open(), and an MTU
change through igb_down() and igb_up(), so the limit is updated before
Rx is enabled again.

The Sashiko review of v4 also points out two older issues that this
series does not change:

- On 2 KiB build_skb rings, igb_skb_pad() leaves exactly
  IGB_MAX_FRAME_BUILD_SKB bytes before skb_shared_info, with no room for
  the 16-byte timestamp header. With Rx timestamping on, frame and
  header can overlap skb_shared_info by up to 12 bytes, or 2 bytes at
  the XDP limit at MTU 1500. This dates from 9cbc948b5a20 ("igb: add XDP
  support"). I left it out of this series: it is a separate problem from
  the one fixed here, and a fix changes the buffer layout and the XDP
  headroom for all igb users, so it needs its own review and testing.
- igb_set_vf_rlpml() let a VF set other VMOLR bits of its own pool. That
  is fixed separately: https://lore.kernel.org/all/20261104-igb-vf-rlpml-v1-1-729621b60eee@aweta.nl/

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

3) AF_XDP zero-copy with 2 KiB chunks (patch 3)

  receiver:  ip link set eth0 mtu 1500
             ethtool -L eth0 combined 1
             hwstamp_ctl -i eth0 -r 1
             xdpsock -i eth0 -q 0 -r -z -N -f 2048
  peer:      ping -c 50 -i 0.02 -s 1472 <receiver>

  xdpsock is from xdp-project/bpf-examples (AF_XDP-example). It also
  takes ARP, so the peer needs a fresh ARP entry before it starts.
  Compare rx_packets (MAC) with rx_queue_0_packets in ethtool -S:

    without the series    68 frames, 118 descriptors
    this series           64 frames, 64 descriptors

  At MTU 3000, -f 4096 receives 3014-byte frames in one buffer. Binding
  with -f 2048 at MTU 3000 was refused with EOPNOTSUPP by the new check
  on the 6.14.9 test kernel; current kernels refuse it earlier, in
  xp_assign_dev(), with EINVAL.

Tested on an I350 with these patches applied to the igb driver of
kernel 6.14.9 (the series itself is against v7.1-rc7), with the steps
above: results as listed. The v3 line is from an earlier run with an
XDP program dropping ICMP. Also checked: XDP attach at MTU 1500 and
3030 works, at MTU 3046 it is refused, as is an MTU change to 3046
with XDP attached. With two VFs allocated (booted with pci=realloc),
step 2 gives the same picture: three leftover frames without the
series, none with it, as the PF pool limit in VMOLR drops the frames.
In step 3, 98-byte frames and 4 KiB chunks take one descriptor per
frame with and without the series. With XDP attached, rx-all stays off
and legacy-rx cannot be changed, and XDP attach is refused with rx-all
on, or with legacy-rx on at MTU 3000, also when it was set while the
interface was down. RLPML and the PF pool's VMOLR limit read back as
expected with and without XDP and VFs, also after each of about 200 MTU
changes with XDP and two VFs. Patch 4 is not reproduced: with patch 3 the I350
no longer splits frames in zero-copy mode.
The steps above were repeated on kernel 7.3.1 with the series applied
to the v7.3 igb driver, with the same results; without VFs, as that
boot lacked pci=realloc.
Not tested: PAGE_SIZE >= 8192.

The patches, their descriptions and this cover letter were prepared
with the help of an AI coding assistant (Claude). I reviewed them and
ran the tests above on my test bench.

[1] https://lore.kernel.org/all/20261025065154.2037149-1-p@1g4.org/
[2] https://lore.kernel.org/all/20261028083344.3047350-1-p@1g4.org/

Changes in v5:
- Patch 1: v4 also subtracted the timestamp header from the build_skb
  frame limit, so XDP no longer attached at MTU 1495-1510 on x86
  (1493-1508 where NET_IP_ALIGN is 2), including the default MTU 1500.
  Only subtract the header where the limit is the hardware buffer size,
  and compute it from the adapter state instead of the ring flags. Skip
  the check when XDP is removed, so a program can always be detached.
- Patch 1: refuse XDP with rx-all and legacy-rx changes with XDP
  attached, and turn rx-all back on after XDP removal if it was
  requested meanwhile. Program RLPML and the PF pool limit from
  igb_configure() instead of igb_set_rx_mode(). With XDP attached, an
  MTU change can now move from 2 KiB to 3 KiB buffers. Added
  Suggested-by: Maciej.
- Patch 1: the issues above were also reported by the Sashiko review
  of v4.
- Patch 2: no code change. Commit message: igc is fixed by Paul's
  series, not by this patch; the loss is per continuation buffer, not
  only at the tail; the possible size wrap is described (Sashiko).
- New patch 3: AF_XDP zero-copy Rx buffer size, as asked by Maciej.
- New patch 4: drop zero-copy frames that span several descriptors;
  depends on patch 3.
- Link to v4: https://patch.msgid.link/20261102-igb-rx-ts-fix-v4-0-8785124c5d23@aweta.nl

Changes in v4:
- New patch 1: limit the receive length while XDP is attached, so that
  skb == NULL reliably marks the first buffer (Sashiko review), as
  done for igc.
- Patch 2: no code change; added a note that it relies on patch 1.
- Link to v3: https://patch.msgid.link/20260625-igb-rx-ts-fix-v3-1-99b3efa08dca@aweta.nl

---
Tjerk Kusters (4):
      igb: do not let XDP frames span more than one Rx buffer
      igb: only strip Rx timestamp header on the first buffer of a frame
      igb: do not split AF_XDP zero-copy frames over several Rx buffers
      igb: drop AF_XDP zero-copy frames that span several Rx buffers

 drivers/net/ethernet/intel/igb/igb.h         |  10 ++
 drivers/net/ethernet/intel/igb/igb_ethtool.c |   9 ++
 drivers/net/ethernet/intel/igb/igb_main.c    | 181 ++++++++++++++++++++-------
 drivers/net/ethernet/intel/igb/igb_xsk.c     |  42 ++++++-
 4 files changed, 194 insertions(+), 48 deletions(-)
---
base-commit: 2d3090a8aeb596a26935db0955d46c9a5db5c6ce
change-id: 20260619-igb-rx-ts-fix-cd70585ee316

Best regards,
--  
Tjerk Kusters <tkusters@aweta.nl>

