import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _openTelegram() async {
    const url = 'https://t.me/sahibalzaman313';
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A3D2E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF06442E),
          title: const Text('حول التطبيق'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, color: Colors.amber.shade300, size: 80),
                const SizedBox(height: 20),
                Text(
                  'تطبيق مسابقة الحج',
                  style: TextStyle(
                    color: Colors.amber.shade300,
                    fontWeight: FontWeight.bold,
                    fontSize: size.width * 0.07,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),
                const Text(
                  'تم برمجة هذا التطبيق لخدمة الإخوة مرشدي الحج، لمساعدتهم في الاستعداد لامتحان إرشاد الحج بشكل علمي وتفاعلي.',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 17,
                      height: 1.6,
                      fontWeight: FontWeight.w400),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 20),
                const Text(
                  'يتضمن التطبيق حالياً 720 سؤالًا فقهيًا موزعة على 36 مرحلة، تحتوي كل مرحلة على 20 سؤالًا. '
                      'ويتميز التطبيق بعدة مزايا عملية ولطيفة، منها:',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 17,
                      height: 1.6,
                      fontWeight: FontWeight.w400),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 16),
                _FeatureItem('تحديد مستوى الصعوبة (سهل، متوسط، صعب)، من خلال التحكم بالحد الأقصى المسموح من الأخطاء في كل مرحلة.'),
                _FeatureItem('إمكانية تشغيل أو إيقاف عداد الوقت أثناء الإجابة.'),
                _FeatureItem('اختيار حجم الخط المناسب.'),
                _FeatureItem('تصميم أنيق وألوان مريحة للعين.'),
                _FeatureItem('إظهار نتيجة كل مرحلة بشكل تفاعلي.'),
                const SizedBox(height: 20),
                const Text(
                  '400 سؤال من هذه الأسئلة مأخوذة من امتحانات الحج للسنوات الأربع الماضية، '
                      'لتضمن أكبر قدر من الواقعية والفائدة.',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 17,
                      height: 1.6,
                      fontWeight: FontWeight.w400),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 20),
                const Text(
                  'قد يتم تحديث التطبيق لاحقًا بإضافة المزيد من الأسئلة والمحتوى. '
                      'للمزيد من التطبيقات ولمتابعة التحديثات، يمكنكم الانضمام إلى قناتنا على التلكرام عبر الضغط على الزر أدناه:',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 17,
                      height: 1.6,
                      fontWeight: FontWeight.w400),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade600,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _openTelegram,
                  icon: const Icon(Icons.telegram, color: Colors.white, size: 26),
                  label: const Text(
                    'الانضمام إلى القناة',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  '© مكتبة القائم - جميع الحقوق محفوظة',
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final String text;
  const _FeatureItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ',
              style: TextStyle(color: Colors.amber, fontSize: 20, height: 1.5)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
