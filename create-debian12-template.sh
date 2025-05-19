#!/bin/bash

# -------------------------
# Paramètres à modifier
# -------------------------
VMID=9000
VMNAME="debian12-cloudinit"
STORAGE="local-lvm"                 # Ou autre stockage (ex: "local", "ssd", etc.)
BRIDGE="vmbr0"
ISO_URL="https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
DISK_IMAGE="debian-12-genericcloud-amd64.qcow2"
SSH_KEY_PATH="$HOME/.ssh/id_rsa.pub"  # Facultatif — injecte la clé dans le template

# -------------------------
# Dépendance requise
# -------------------------
echo "🔍 Vérification des dépendances..."
if ! command -v virt-customize >/dev/null 2>&1; then
  echo "❌ 'virt-customize' manquant. Installer avec : sudo apt install libguestfs-tools"
  exit 1
fi

# -------------------------
# Téléchargement de l'image
# -------------------------
echo "🔽 Téléchargement de l'image Debian 12 Cloud..."
wget -O $DISK_IMAGE $ISO_URL

# -------------------------
# Personnalisation de l’image (Cloud-Init + console série)
# -------------------------
echo "🛠️ Personnalisation de l’image..."
virt-customize -a $DISK_IMAGE \
  --install qemu-guest-agent \
  --run-command 'sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"console=ttyS0 console=tty1\"/" /etc/default/grub' \
  --run-command 'update-grub' \
  --root-password password:debian \
  --hostname debian-cloudinit

# -------------------------
# Création de la VM
# -------------------------
echo "⚙️ Création de la VM ID $VMID..."
qm create $VMID \
  --name $VMNAME \
  --memory 2048 \
  --cores 2 \
  --net0 virtio,bridge=$BRIDGE \
  --ostype l26

# -------------------------
# Import du disque QCOW2
# -------------------------
echo "📦 Import du disque..."
qm importdisk $VMID $DISK_IMAGE $STORAGE

# -------------------------
# Configuration du disque et du Cloud-Init
# -------------------------
qm set $VMID \
  --scsihw virtio-scsi-pci \
  --scsi0 $STORAGE:vm-$VMID-disk-0 \
  --ide2 $STORAGE:cloudinit \
  --boot c \
  --bootdisk scsi0 \
  --serial0 socket \
  --vga serial0 \
  --agent enabled=1

# -------------------------
# Conversion en template
# -------------------------
echo "📸 Conversion en template..."
qm template $VMID

# -------------------------
# Nettoyage
# -------------------------
rm -f $DISK_IMAGE

echo "✅ Template $VMNAME ($VMID) prêt à être utilisé avec Proxmox ou Terraform 🎉"
