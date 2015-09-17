# faux_crypt_fs
Encrypt key system directories when full-disk encryption is not available.

This is **NOT** a substitute for full-disk encryption.

## Why?

Full-disk encryption is not possible for some dedicated servers. This is particularly the case for budget hosting providers like [Kimsufi][c762b802].

  [c762b802]: http://www.kimsufi.com/ "Kimsufi servers"

Full-disk encryption is necessary for data protection in cases when the actual physical server has been compromised (e.g.: stolen). These scripts provide a similar concept when the sysadmin doesn't have access to bootable media or a server with Pre-Execution Environment (PXE) support.

As a proof of concept, I've created this set of bash scripts which create and encrypt a LVM partition with some system directories in a fresh CentOS 7 installation.

The directories will be mounted as separate logical volumes:

- home
- opt
- root
- srv
- tmp
- var

## How does it work?

Each directory is mounted **on top** of the true system directory. Therefore, once mounted, the system will start reading and writing data from the encrypted volumes.

When the server shuts down, the encrypted LVM is locked and data is safely stored.

The theory and practice would be very similar to having full-disk encryption. However, there are important risks and caveats to consider.

## Risks

This is more a proof of concept than anything else. It is strongly advised that you're familiar with Linux filesystems and standard directory structures before running and customising the scripts.

It's important to understand that we'll be mounting logical volumes on top of system directories which were used by the system during boot. After the first run of the scripts, there shouldn't be any missing data.

However, after each reboot, the system will load the true system directories. As a result, this _"faux"_ method generates additional admin tasks and critical caveats:

- Some services may be enabled with systemd but won't start on boot because they won't see the data they need (it's locked away until mounted manually). Starting services manually or with scripts _after_ booting would still work.
- If `/var` is to be encrypted in this manner, watch out for services which use subdirectories in it. Logging should be enabled remotely on a loghost.
- Encrypting the `/usr` directory would still work. But this should be highly experimental territory only.
- Anything that you may not expect.

The scripts have been tested in [Kimsufi][e1ad59ed] servers, which are not recommended for production setups.

  [e1ad59ed]: http://www.kimsufi.com/ "Kimsufi servers"

## Usage

The scripts are divided in three parts:


1. **_crypt_prep.sh_: A simple set of commands to prepare the formatting of partitions. It's written for a fresh CentOS 7 install with**:
  - `/dev/sda1` as root with 30GB. It will only hold fresh installation files
  - `/dev/sda2`  as swap. Kimsufi has a policy that a swap partition is compulsory for new servers. Part II of the script will create a new LV for swap

  A new recommended setup with fdisk/gdisk would be:

   - Delete swap partition `/dev/sda2`
  - Create a new LVM-type partition in `/dev/sda2`

2. **_crypt_setup.sh_: This is where the magic happens. The script will create, encrypt and mount all the directories listed in $CRYPT_FOLDERS. Some things to consider:**

  - Permissions and SELinux security contexts will be the same as in the non-encrypted partition
  - The var `$CRYPT_FOLDERS` stores an associative array with directories and desired sizes
  - A swap LV will be created by default

3. **_crypt_mount.sh_: A script to run after reboot**

## Help

Please create an issue to start a discussion, give feedback or report issues.
