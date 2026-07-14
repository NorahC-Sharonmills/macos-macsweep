Bạn là một Senior macOS Engineer chuyên Swift, SwiftUI, AppKit, FileManager, sandboxing, security-scoped access và tối ưu hệ thống macOS.

Hãy xây dựng một ứng dụng macOS native hoàn chỉnh có tên tạm thời là **Mac Deep Cleaner**, dùng:

* Swift 6
* SwiftUI
* AppKit khi SwiftUI không đáp ứng đủ
* MVVM hoặc Clean Architecture
* Xcode project chạy được trực tiếp
* Hỗ trợ macOS 14 trở lên
* Hỗ trợ cả Apple Silicon và Intel
* Không dùng Electron
* Không dùng Python
* Không dùng framework giao diện đa nền tảng
* Không phụ thuộc vào dịch vụ cloud

## Mục tiêu sản phẩm

Ứng dụng giúp người dùng phân tích dung lượng ổ đĩa, tìm file không còn sử dụng, cache, log, dữ liệu ứng dụng đã gỡ, file lập trình nặng và các file lớn lâu ngày không mở.

Ứng dụng phải ưu tiên an toàn. Tuyệt đối không tự động xóa file hệ thống hoặc file cá nhân nếu chưa có xác nhận rõ ràng từ người dùng.

Ứng dụng không được quảng cáo sai rằng có thể “tăng RAM”, “tăng tốc CPU” hoặc “tối ưu thần kỳ”.

## Các màn hình chính

### 1. Dashboard

Hiển thị:

* Tổng dung lượng ổ
* Dung lượng đã sử dụng
* Dung lượng còn trống
* Dung lượng có thể dọn
* Biểu đồ phân loại dung lượng
* Các nhóm:

  * Applications
  * Downloads
  * Documents
  * Developer Files
  * Cache
  * Logs
  * iOS Backups
  * Mail Attachments
  * Messages Attachments
  * Large Files
  * Old Files
  * Duplicate Files
  * Application Leftovers

Có nút:

* Scan Mac
* Review Results
* Clean Selected

Không tự động chạy quét ngay khi mở ứng dụng.

### 2. Storage Analyzer

Quét và hiển thị cây thư mục theo dung lượng.

Yêu cầu:

* Quét bất đồng bộ
* Không làm treo giao diện
* Có tiến trình quét
* Có nút dừng quét
* Có thể mở file trong Finder
* Có thể Reveal in Finder
* Có thể Quick Look file
* Có thể sắp xếp theo:

  * Size
  * Name
  * Last Modified
  * Last Accessed
  * File Type

Hiển thị rõ:

* Đường dẫn đầy đủ
* Dung lượng
* Ngày sửa gần nhất
* Ngày truy cập gần nhất nếu filesystem hỗ trợ
* Loại file
* Trạng thái có thể xóa an toàn hay cần kiểm tra thủ công

Không tự động coi file cũ là file rác.

### 3. Large Files

Cho phép lọc:

* Lớn hơn 100 MB
* Lớn hơn 500 MB
* Lớn hơn 1 GB
* Lớn hơn 5 GB
* Giá trị tùy chỉnh

Có bộ lọc theo thời gian:

* Không sửa trong 30 ngày
* 90 ngày
* 180 ngày
* 365 ngày

Cho phép preview, mở Finder, đưa vào Trash.

### 4. Cache Cleaner

Quét các thư mục cache phổ biến:

* ~/Library/Caches
* ~/Library/Logs
* ~/Library/Saved Application State
* ~/Library/WebKit
* ~/Library/HTTPStorages

Phân nhóm cache theo ứng dụng.

Hiển thị:

* Tên ứng dụng
* Bundle identifier
* Đường dẫn
* Dung lượng
* Mức độ an toàn:

  * Safe
  * Review
  * Do Not Delete

Không xóa toàn bộ thư mục cha nếu chỉ nên xóa nội dung cache.

Không đụng vào:

* Keychains
* Mail database
* Messages database
* Photos Library
* iCloud Drive metadata
* System framework
* User documents

### 5. Application Uninstaller

Liệt kê ứng dụng trong:

* /Applications
* ~/Applications

Hiển thị:

* Icon
* Tên ứng dụng
* Bundle ID
* Phiên bản
* Dung lượng app
* Ngày sử dụng gần nhất nếu lấy được
* Các file liên quan

Tìm leftovers theo Bundle ID và tên ứng dụng trong:

* ~/Library/Application Support
* ~/Library/Caches
* ~/Library/Preferences
* ~/Library/Logs
* ~/Library/Containers
* ~/Library/Group Containers
* ~/Library/Saved Application State
* ~/Library/LaunchAgents

Phải phân biệt:

* File thuộc riêng ứng dụng
* File có thể đang được dùng chung
* Group Container có thể chứa dữ liệu của nhiều ứng dụng

Không xóa Group Container hoặc Application Support nếu không chắc chắn.

Khi uninstall:

* Đưa app vào Trash
* Đưa các file được người dùng chọn vào Trash
* Không dùng rm -rf mặc định
* Cho phép bỏ chọn từng file
* Hiển thị tổng dung lượng sẽ giải phóng

### 6. Developer Cleaner

Phát hiện và phân loại:

#### Xcode

* DerivedData
* Archives
* DeviceSupport
* Simulator data
* Unavailable simulators
* Swift Package Manager cache

#### Node.js

* node_modules
* npm cache
* pnpm store
* Yarn cache

#### Python

* .venv
* venv
* pip cache
* **pycache**

#### Docker

Chỉ hiển thị thông tin nếu Docker CLI tồn tại:

* Images
* Containers
* Build cache
* Volumes

Không tự động xóa Docker volume.

#### Homebrew

* Download cache
* Old package versions
* Casks
* Formula cache

#### Unity

* Library
* Temp
* Logs
* obj

Phải cảnh báo rằng thư mục Unity Library có thể được tạo lại nhưng project sẽ import lại lâu.

Mỗi mục cần có:

* Đường dẫn
* Dung lượng
* Loại dữ liệu
* Có thể tạo lại hay không
* Mức độ an toàn
* Cảnh báo trước khi xóa

### 7. iPhone/iPad Backups

Phân tích:

~/Library/Application Support/MobileSync/Backup

Hiển thị:

* Tên thiết bị nếu lấy được từ metadata
* Ngày backup
* Dung lượng
* Phiên bản iOS nếu có
* Backup được mã hóa hay không nếu xác định được

Không đọc hoặc hiển thị dữ liệu riêng tư bên trong backup.

### 8. Duplicate Finder

Tìm file trùng bằng quy trình tối ưu:

1. Nhóm theo dung lượng
2. So sánh partial hash
3. Chỉ tính full hash khi cần
4. Không tải toàn bộ file lớn lên RAM

Hỗ trợ SHA-256.

Mặc định bỏ qua:

* System folders
* Library databases
* Photos Library package
* Git object database
* node_modules
* .venv
* Package contents

Cho phép người dùng bật lại từng khu vực.

Không tự chọn bản nào để xóa.

### 9. Cleaning History

Lưu lịch sử:

* Ngày dọn
* File đã đưa vào Trash
* Dung lượng
* Loại dữ liệu
* Đường dẫn cũ

Không cần chức năng phục hồi riêng vì file nằm trong Trash.

Không lưu nội dung file.

## Nguyên tắc xóa file

Mọi thao tác xóa mặc định phải dùng:

* FileManager trashItem
* NSWorkspace recycle nếu phù hợp

Không dùng:

* rm -rf
* sudo rm
* Shell command không được kiểm soát

Trước khi xóa phải hiển thị:

* Tổng số file
* Tổng dung lượng
* Danh sách file
* Cảnh báo rủi ro
* Nút Cancel
* Nút Move to Trash

Chỉ dùng xóa vĩnh viễn nếu người dùng chủ động chọn trong Advanced Settings và xác nhận lần hai.

## Quyền truy cập macOS

Thiết kế đúng quy trình cấp quyền:

* Full Disk Access
* User-selected folder access
* Security-scoped bookmarks nếu cần
* Không tìm cách vượt TCC
* Không tự ý chạy bằng root
* Không dùng sudo trong ứng dụng

Nếu thiếu quyền:

* Hiển thị màn hình giải thích
* Có nút mở đúng trang System Settings
* Nói rõ chức năng nào đang bị giới hạn
* Không crash
* Không giả vờ đã quét đầy đủ

## Hiệu năng

* Dùng Swift Concurrency
* async/await
* TaskGroup khi phù hợp
* Giới hạn số lượng tác vụ đọc file đồng thời
* Không block MainActor
* Có cancellation
* Có progress reporting
* Có xử lý symbolic link để tránh vòng lặp
* Không đi theo mount point ngoài ý muốn
* Không quét volume mạng theo mặc định
* Không đọc toàn bộ file để tính dung lượng
* Dùng URLResourceValues và FileManager enumerator

Thiết kế hệ thống cache kết quả scan nhưng phải phát hiện file đã thay đổi.

## Bảo mật

* Mọi dữ liệu xử lý hoàn toàn local
* Không analytics mặc định
* Không telemetry
* Không upload danh sách file
* Không gửi đường dẫn file ra ngoài
* Không thu thập dữ liệu cá nhân

Có trang Privacy giải thích rõ điều này.

## Giao diện

Phong cách:

* Native macOS
* Sidebar kiểu System Settings
* Toolbar rõ ràng
* Hỗ trợ Light Mode và Dark Mode
* Hỗ trợ Dynamic Type
* Hỗ trợ bàn phím
* Có accessibility label
* Không dùng hiệu ứng màu mè quá mức
* Không giả giao diện CleanMyMac
* Không dùng biểu tượng cảnh báo gây sợ hãi

Sidebar gồm:

* Dashboard
* Storage Analyzer
* Large Files
* Cache
* Applications
* Developer
* iOS Backups
* Duplicates
* Cleaning History
* Settings

## Settings

Bao gồm:

* Minimum file size
* Old file threshold
* Excluded folders
* Excluded extensions
* Follow symbolic links: mặc định tắt
* Scan external volumes: mặc định tắt
* Scan network volumes: mặc định tắt
* Permanent deletion: mặc định tắt
* Confirmation before cleaning: luôn bật
* Show hidden files
* Developer mode

## Kiến trúc code

Chia module rõ ràng:

* App
* Models
* Views
* ViewModels
* Services
* Scanners
* FileSystem
* Permissions
* Persistence
* Utilities
* Tests

Các service tối thiểu:

* DiskUsageService
* FileScannerService
* CacheScannerService
* ApplicationScannerService
* DeveloperScannerService
* DuplicateScannerService
* PermissionService
* TrashService
* CleaningHistoryService
* ExclusionService

Mỗi scanner phải tuân theo protocol chung để có thể mở rộng.

Ví dụ:

* identifier
* displayName
* scan()
* cancel()
* riskLevel
* supportedPaths

Không nhét toàn bộ logic vào ViewModel.

## Testing

Viết:

* Unit tests
* File scanner tests
* Duplicate detection tests
* Exclusion rule tests
* Trash operation mock tests
* Permission state tests
* Tests với symbolic links
* Tests với file không có quyền đọc
* Tests với đường dẫn Unicode và tiếng Việt
* Tests với file bị xóa trong lúc đang scan

Không chạy test trên thư mục thật của người dùng.

Tạo temporary directory fixture cho test.

## Logging

Dùng os.Logger.

Không log:

* Nội dung file
* Tên file nhạy cảm ở production
* Token
* Dữ liệu người dùng

Có mức:

* Debug
* Info
* Warning
* Error

## Yêu cầu triển khai

Thực hiện theo từng phase nhưng tiếp tục triển khai toàn bộ, không dừng lại chỉ để đưa kế hoạch.

### Phase 1

* Khởi tạo Xcode project
* Kiến trúc app
* Sidebar
* Dashboard
* Disk usage
* Permission handling
* Storage scan cơ bản

### Phase 2

* Large Files
* Cache Scanner
* Application Uninstaller
* Trash workflow

### Phase 3

* Developer Cleaner
* iOS Backup Scanner
* Duplicate Finder

### Phase 4

* Settings
* Exclusions
* History
* Tests
* Performance optimization
* Accessibility
* Error handling

## Đầu ra bắt buộc

1. Tạo toàn bộ source code.
2. Tạo README.md.
3. Tạo ARCHITECTURE.md.
4. Tạo SECURITY.md.
5. Tạo PRIVACY.md.
6. Tạo TESTING.md.
7. Tạo danh sách entitlement cần thiết.
8. Ghi rõ cách bật Full Disk Access.
9. Ghi rõ cách build Debug và Release.
10. Ghi rõ giới hạn của macOS sandbox.
11. Đảm bảo project compile được.
12. Chạy test và sửa lỗi đến khi test pass.
13. Không để placeholder giả.
14. Không tạo dữ liệu demo làm người dùng tưởng là dữ liệu thật.
15. Không sử dụng API private của Apple.

## Lưu ý quan trọng

* Không được tự động xóa file chỉ vì file đã cũ.
* Không gọi mọi cache là “junk”.
* Không can thiệp SIP.
* Không vượt Gatekeeper.
* Không thay đổi quyền file bằng chmod hàng loạt.
* Không yêu cầu root nếu không thật sự cần.
* Không xóa file trong /System.
* Không xóa file trong /Library nếu chưa có rule an toàn rõ ràng.
* Không xóa dữ liệu Docker volume.
* Không xóa Git repository.
* Không xóa source code.
* Không xóa Photos Library.
* Không xóa iCloud file chưa được tải đầy đủ.
* Không đi theo alias hoặc symbolic link ngoài phạm vi scan.
* Phải xử lý đường dẫn có dấu tiếng Việt.
* Khi không chắc một file có an toàn để xóa hay không, đánh dấu Review thay vì Safe.

Bắt đầu bằng cách kiểm tra môi trường hiện tại, sau đó tạo cấu trúc project và triển khai đầy đủ theo các phase trên.
