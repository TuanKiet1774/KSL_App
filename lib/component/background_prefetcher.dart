import 'package:ksl/controller/topicController.dart';
import 'package:ksl/controller/learnedWordController.dart';
import 'package:ksl/controller/authController.dart';

import '../controller/wordController.dart';

class BackgroundPrefetcher {
  static Future<void> start() async {
    try {
      await AuthController.getProfile();
      await LearnedWordController.syncExp();
      final topicResult = await TopicController.getAllTopics(page: 1, limit: 10);
      
      if (topicResult['success']) {
        final List topics = topicResult['data'];
        for (var topic in topics) {
          WordController.getWordsByTopic(topic.id, page: 1, limit: 10);
        }
      }
      
      await LearnedWordController.getMyLearnedWords(page: 1, limit: 10);
      
      print('Background pre-fetching completed successfully.');
    } catch (e) {
      print('Background pre-fetching error: $e');
    }
  }
}
