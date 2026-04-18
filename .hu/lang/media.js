'use strict';

const fs = require('fs');
const pathMod = require('path');

const ESC = '\x1b[';
const RESET = `${ESC}0m`;
const DIM = `${ESC}2m`;
const BOLD = `${ESC}1m`;
const CYAN = `${ESC}36m`;

const MEDIA_TYPES = {
  // Images
  '.png': 'PNG Image', '.jpg': 'JPEG Image', '.jpeg': 'JPEG Image',
  '.gif': 'GIF Image', '.bmp': 'BMP Image', '.webp': 'WebP Image',
  '.svg': 'SVG Image', '.ico': 'Icon', '.tiff': 'TIFF Image',
  '.tif': 'TIFF Image', '.heic': 'HEIC Image', '.heif': 'HEIF Image',
  '.avif': 'AVIF Image', '.psd': 'Photoshop Document',
  // Audio
  '.mp3': 'MP3 Audio', '.wav': 'WAV Audio', '.aac': 'AAC Audio',
  '.flac': 'FLAC Audio', '.ogg': 'Ogg Audio', '.m4a': 'M4A Audio',
  '.wma': 'WMA Audio', '.aiff': 'AIFF Audio',
  // Video
  '.mp4': 'MP4 Video', '.mov': 'QuickTime Video', '.avi': 'AVI Video',
  '.mkv': 'MKV Video', '.webm': 'WebM Video', '.wmv': 'WMV Video',
  '.flv': 'FLV Video', '.m4v': 'M4V Video',
  // Documents
  '.pdf': 'PDF Document',
  '.doc': 'Word Document', '.docx': 'Word Document',
  '.xls': 'Excel Spreadsheet', '.xlsx': 'Excel Spreadsheet',
  '.ppt': 'PowerPoint', '.pptx': 'PowerPoint',
  '.pages': 'Pages Document', '.numbers': 'Numbers Spreadsheet',
  '.key': 'Keynote Presentation',
  // Archives
  '.zip': 'ZIP Archive', '.tar': 'Tar Archive', '.gz': 'GZip Archive',
  '.rar': 'RAR Archive', '.7z': '7-Zip Archive', '.dmg': 'Disk Image',
  // Fonts
  '.ttf': 'TrueType Font', '.otf': 'OpenType Font',
  '.woff': 'Web Font', '.woff2': 'Web Font',
};

function formatSize(bytes) {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  if (bytes < 1024 * 1024 * 1024) return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  return `${(bytes / (1024 * 1024 * 1024)).toFixed(1)} GB`;
}

module.exports = {
  type: 'viewer',
  name: 'Media',
  extensions: Object.keys(MEDIA_TYPES),

  loadData(node) {
    if (node._viewerData !== undefined) return node._viewerData;
    try {
      const stat = fs.statSync(node.path);
      node._viewerData = {
        path: node.path,
        name: pathMod.basename(node.path),
        ext: pathMod.extname(node.path).toLowerCase(),
        size: stat.size,
        modified: stat.mtime,
      };
    } catch (e) {
      node._viewerData = null;
    }
    return node._viewerData;
  },

  renderView(data, contentWidth) {
    const lines = [];
    const boxWidth = Math.min(contentWidth - 4, 60);
    const margin = Math.max(2, Math.floor((contentWidth - boxWidth) / 2));

    const mediaType = MEDIA_TYPES[data.ext] || 'File';

    lines.push(`${BOLD}${data.name}${RESET}`);
    lines.push('');
    lines.push(`${DIM}Type${RESET}      ${mediaType}`);
    lines.push(`${DIM}Size${RESET}      ${formatSize(data.size)}`);
    lines.push(`${DIM}Modified${RESET}  ${data.modified.toLocaleString()}`);

    return { lines, margin };
  },
};
