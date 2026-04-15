import 'package:flutter/material.dart';
import 'package:ksl/component/app_colors.dart';

class InformationView extends StatefulWidget {
  const InformationView({super.key});

  @override
  State<InformationView> createState() => _InformationViewState();
}

class _InformationViewState extends State<InformationView> {
  final ScrollController _scrollController = ScrollController();
  
  // Keys for scrolling to sections
  final GlobalKey _keyWhatIs = GlobalKey();
  final GlobalKey _keyHistory = GlobalKey();
  final GlobalKey _keyCharacteristics = GlobalKey();

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showTableOfContents() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mục lục',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryTeal,
              ),
            ),
            const SizedBox(height: 15),
            const Divider(),
            _buildTOCItem(
              icon: Icons.help_outline_rounded,
              title: 'Ngôn ngữ ký hiệu là gì?',
              onTap: () {
                Navigator.pop(context);
                _scrollToSection(_keyWhatIs);
              },
            ),
            _buildTOCItem(
              icon: Icons.history_rounded,
              title: 'Sơ lược lịch sử hình thành',
              onTap: () {
                Navigator.pop(context);
                _scrollToSection(_keyHistory);
              },
            ),
            _buildTOCItem(
              icon: Icons.featured_play_list_rounded,
              title: 'Đặc điểm ngôn ngữ ký hiệu Việt Nam',
              onTap: () {
                Navigator.pop(context);
                _scrollToSection(_keyCharacteristics);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTOCItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.accentOrange),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: AppColors.textDark,
        ),
      ),
      onTap: onTap,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      floatingActionButton: FloatingActionButton(
        onPressed: _showTableOfContents,
        backgroundColor: AppColors.primaryTeal,
        elevation: 10,
        child: const Icon(Icons.list_alt_rounded, color: Colors.white),
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.primaryTeal,
            title: const Text(
              'Một số thông tin liên quan',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section 1: Ngôn ngữ ký hiệu là gì?
                  Container(
                    key: _keyWhatIs,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: const Border(
                        left: BorderSide(color: AppColors.accentOrange, width: 4),
                      ),
                    ),
                    child: const Text(
                      'Ngôn ngữ ký hiệu là gì?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/MinhHoa1.jpg',
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported, size: 50),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  RichText(
                    textAlign: TextAlign.justify,
                    text: TextSpan(
                      children: [
                        const WidgetSpan(child: SizedBox(width: 30)),
                        TextSpan(
                          text: 'Ngôn ngữ ký hiệu, còn được gọi là thủ ngữ hay ngôn ngữ thị giác, là ngôn ngữ sử dụng hình dạng bàn tay, chuyển động cơ thể, cử chỉ điệu bộ và sự thể hiện trên khuôn mặt để giao tiếp trao đổi kinh nghiệm, suy nghĩ, nhu cầu và cảm xúc.',
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w500,
                            fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  RichText(
                    textAlign: TextAlign.justify,
                    text: TextSpan(
                      children: [
                        const WidgetSpan(child: SizedBox(width: 30)),
                        TextSpan(
                          text: 'Đây là một hệ thống giao tiếp đặc biệt được sử dụng chủ yếu bởi cộng đồng người khiếm thính. Đối với những người bẩm sinh không thể nghe hoặc nói, đây là phương tiện quan trọng giúp họ kết nối và trao đổi thông tin với thế giới xung quanh.',
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: AppColors.textDark,
                            fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  RichText(
                    textAlign: TextAlign.justify,
                    text: TextSpan(
                      children: [
                        const WidgetSpan(child: SizedBox(width: 30)),
                        TextSpan(
                          text: 'Thay vì sử dụng âm thanh, ngôn ngữ ký hiệu truyền tải ý nghĩa thông qua cử chỉ của bàn tay, kết hợp với biểu cảm khuôn mặt, ánh mắt và chuyển động của cơ thể. Nhờ sự phối hợp linh hoạt của các yếu tố này, người sử dụng có thể diễn đạt đầy đủ suy nghĩ, cảm xúc và ý tưởng, tạo nên một hệ thống ngôn ngữ sinh động và giàu tính biểu đạt.',
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: AppColors.textDark,
                            fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),

                  // Section 2: Sơ lược lịch sử hình thành
                  Container(
                    key: _keyHistory,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: const Border(
                        left: BorderSide(color: AppColors.accentOrange, width: 4),
                      ),
                    ),
                    child: const Text(
                      'Sơ lược lịch sử hình thành',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  RichText(
                    textAlign: TextAlign.justify,
                    text: TextSpan(
                      children: [
                        const WidgetSpan(child: SizedBox(width: 30)),
                        TextSpan(
                          text: 'Ngôn ngữ ký hiệu xuất hiện từ khi nào và ai là người đã tạo ra nó vẫn chưa có câu trả lời chính xác. Cho đến nay, chưa có bằng chứng khoa học xác thực nào xác định rõ nguồn gốc của loại ngôn ngữ này. Tuy nhiên, nhiều giả thuyết cho rằng từ thời tiền sử, khi con người chưa phát triển hoàn thiện ngôn ngữ nói, họ đã sử dụng những cử chỉ, điệu bộ và hành động của cơ thể để bày tỏ suy nghĩ, cảm xúc và trao đổi thông tin với nhau. Chính những hình thức giao tiếp tự nhiên đó được xem là tiền thân của ngôn ngữ ký hiệu ngày nay.',
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: AppColors.textDark,
                            fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.asset(
                          'assets/GirolamoCardano.jpg',
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Geronimo Cardano',
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  RichText(
                    textAlign: TextAlign.justify,
                    text: TextSpan(
                      children: [
                        const WidgetSpan(child: SizedBox(width: 30)),
                        TextSpan(
                          text: 'Từ những năm 384 – 322 thời kỳ trước công nguyên, đã có rất nhiều nhận định và tuyên bố mang tính phân biệt đối xử nặng nề. Mãi cho đến thế kỷ XVI, một nhà toán học và bác sĩ người Ý, ',
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: AppColors.textDark,
                            fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                          ),
                        ),
                        TextSpan(
                          text: 'Geronimo Cardano',
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: AppColors.textDark,
                            fontWeight: FontWeight.bold,
                            fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                          ),
                        ),
                        TextSpan(
                          text: ' đã nhận ra những người khiếm thính có thể được giáo dục bằng cách sử dụng chữ viết, ông đã áp dụng phương pháp này để giáo dục con tria bị khiếm thính của mình. Từ đó, ông chính là người đã đặt nền móng cho nền giáo dục đối với người khiếm thính.',
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: AppColors.textDark,
                            fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.asset(
                          'assets/JuanPablodeBonet.jpg',
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Juan Pablo de Bonet',
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  RichText(
                    textAlign: TextAlign.justify,
                    text: TextSpan(
                      children: [
                        const WidgetSpan(child: SizedBox(width: 30)),
                        TextSpan(
                          text: 'Vào những năm đầu thế kỷ XVII, một linh mục người Tây Ban Nha, ',
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: AppColors.textDark,
                            fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                          ),
                        ),
                        TextSpan(
                          text: 'Juan Pablo de Bonet',
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: AppColors.textDark,
                            fontWeight: FontWeight.bold,
                            fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                          ),
                        ),
                        TextSpan(
                          text: ' đã đã chuyển tải thành công ý tưởng của ',
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: AppColors.textDark,
                            fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                          ),
                        ),
                        TextSpan(
                          text: 'Geronimo Cardano',
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: AppColors.textDark,
                            fontWeight: FontWeight.bold,
                            fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                          ),
                        ),
                        TextSpan(
                          text: ' thành phương pháp dạy học cho người khiếm thính trong đó sử dụng điệu bộ tự nhiên để dạy phát âm và dạy nói. Sau đó, ông cho xuất bản cuốn sách ',
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: AppColors.textDark,
                            fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                          ),
                        ),
                        TextSpan(
                          text: '“Summary of the letters and the art of teaching speech to the mute”',
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: AppColors.textDark,
                            fontWeight: FontWeight.bold,
                            fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                          ),
                        ),
                        TextSpan(
                          text: ', đây được xem là bản mô tả đầu tiên về ngữ âm học của ngôn ngữ kí hiệu và cách sử dụng ngôn ngữ kí hiệu trong việc giáo dục.',
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: AppColors.textDark,
                            fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.asset(
                          'assets/AbbeCharlesMicheldeLEpee.jpg',
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Abbe Charles Michel de L\'Epee',
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  RichText(
                    textAlign: TextAlign.justify,
                    text: TextSpan(
                      children: [
                        const WidgetSpan(child: SizedBox(width: 30)),
                        TextSpan(
                          text: 'Những tổ chức giáo dục dành cho người khiếm thính hầu như không tồn tại cho đến những năm 1760, một linh mục Công giáo người Pháp,  ',
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: AppColors.textDark,
                            fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                          ),
                        ),
                        TextSpan(
                          text: 'Abbe Charles Michel de L\'Epee',
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: AppColors.textDark,
                            fontWeight: FontWeight.bold,
                            fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                          ),
                        ),
                        TextSpan(
                          text: ' đã tập hợp và phát triển hệ thống hướng dẫn học tiếng Pháp và dạy tôn giáo cho người điếc. Sau đó, ông thành lập trường công đầu tiên dành cho người khiếm thính ở Pari. Tại ngôi trường này, lần đầu tiên trên thế giới, những người khiếm thính được tập hợp lại và được giáo dục theo nhóm đoàn thể.',
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: AppColors.textDark,
                            fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Section 3: Đặc điểm ngôn ngữ ký hiệu Việt Nam
                  Container(
                    key: _keyCharacteristics,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: const Border(
                        left: BorderSide(color: AppColors.accentOrange, width: 4),
                      ),
                    ),
                    child: const Text(
                      'Đặc điểm ngôn ngữ ký hiệu Việt Nam',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  RichText(
                    textAlign: TextAlign.justify,
                    text: TextSpan(
                      children: [
                        const WidgetSpan(child: SizedBox(width: 30)),
                        TextSpan(
                          text: 'Ngôn ngữ ký hiệu không phải là một hệ thống ngôn ngữ thống nhất được quy định và sử dụng chung trên toàn thế giới. Thay vào đó, mỗi cộng đồng người khiếm thính ở các quốc gia khác nhau đều phát triển những ngôn ngữ ký hiệu riêng, mang những đặc trưng riêng biệt. Vì vậy, trên thế giới tồn tại rất nhiều ngôn ngữ ký hiệu khác nhau, chứ không chỉ một hay hai loại. Sự đa dạng này hình thành từ những khác biệt về văn hoá, vùng miền và bối cảnh xã hội của từng cộng đồng.',
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: AppColors.textDark,
                            fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  RichText(
                    textAlign: TextAlign.justify,
                    text: TextSpan(
                      children: [
                        const WidgetSpan(child: SizedBox(width: 30)),
                        TextSpan(
                          text: 'Hiện nay, ước tính có khoảng 300 ngôn ngữ ký hiệu đang được sử dụng trên toàn thế giới. Trong số đó, có những ngôn ngữ chỉ được sử dụng trong phạm vi một địa phương hoặc cộng đồng nhỏ, trong khi một số khác lại được sử dụng rộng rãi bởi hàng triệu người khiếm thính.',
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: AppColors.textDark,
                            fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  RichText(
                    textAlign: TextAlign.justify,
                    text: TextSpan(
                      children: [
                        const WidgetSpan(child: SizedBox(width: 30)),
                        TextSpan(
                          text: 'Ngôn ngữ ký hiệu Việt Nam – ',
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: AppColors.textDark,
                            fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                          ),
                        ),
                        TextSpan(
                          text: 'VSL',
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: AppColors.textDark,
                            fontWeight: FontWeight.bold,
                            fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                          ),
                        ),
                        TextSpan(
                          text: ' cũng có sự tương tự với ',
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: AppColors.textDark,
                            fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                          ),
                        ),
                        TextSpan(
                          text: 'ASL',
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: AppColors.textDark,
                            fontWeight: FontWeight.bold,
                            fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                          ),
                        ),
                        TextSpan(
                          text: ' và các ngôn ngữ ký hiệu khác trên thế giới, chúng đều có sự giản lược và nhấn mạnh trọng tâm. Sự rút gọn một số thành phần trong câu và sự sắp xếp trật tự các từ trong câu có sự khác biệt với ngôn ngữ thông thường.',
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: AppColors.textDark,
                            fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  RichText(
                    textAlign: TextAlign.justify,
                    text: TextSpan(
                      children: [
                        const WidgetSpan(child: SizedBox(width: 30)),
                        TextSpan(
                          text: 'Ngôn ngữ ký hiệu có cấu trúc rất khác với ngôn ngữ nói. Nếu như khi nói ta sẽ có cấu trúc là đối tượng + động từ + thành phần phụ, thì đối với ngôn ngữ ký hiệu sẽ làm ký hiệu đề cập đến các đối tượng được nhắc đến, sau đó mới dẫn giải những thông tin liên quan khác. Ví dụ khi muốn nói “Tôi muốn mua 1 thùng sữa”, ta sẽ ký hiệu lần lượt ',
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: AppColors.textDark,
                            fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                          ),
                        ),
                        TextSpan(
                          text: '“Tôi”, “Thùng sữa”, “1”, “Mua”',
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: AppColors.textDark,
                            fontWeight: FontWeight.bold,
                            fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  RichText(
                    textAlign: TextAlign.justify,
                    text: TextSpan(
                      children: [
                        const WidgetSpan(child: SizedBox(width: 30)),
                        TextSpan(
                          text: 'Trong ngôn ngữ ký hiệu, một số loại từ như giới từ, liên từ và từ tình thái thường được lược bỏ để đảm bảo tính ngắn gọn và tập trung vào nội dung chính của thông điệp. Những từ này chủ yếu đóng vai trò bổ trợ ngữ pháp, thể hiện quan hệ giữa các thành phần câu hoặc sắc thái cảm xúc, nên chúng không mang nhiều thông tin cốt lõi trong quá trình truyền đạt ý nghĩa. Vì vậy, việc giản lược chúng giúp câu ký hiệu rõ ràng, trực tiếp và dễ hiểu hơn.',
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: AppColors.textDark,
                            fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
