import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project/contants/api_contants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final nicknameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  String? selectedSport;
  String? selectedBirthYear;
  String? selectedRegion;
  XFile? profileImage;

  final sports = ['축구', '풋살', '테니스', '배드민턴', '탁구', '볼링'];
  final years = List.generate(50, (index) => (DateTime.now().year - index).toString());
  final regions = ['서울', '경기', '부산', '대구', '광주', '제주'];

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
  }

  Future<void> fetchUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    if (token == null) return;

    final dio = Dio();
    final res = await dio.get(
      "${ApiConstants.baseUrl}/users/my-info",
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    if (res.statusCode == 200) {
      final data = res.data;
      setState(() {
        nicknameController.text = data['nickname'] ?? '';
        selectedSport = data['preferSports'];
        selectedBirthYear = data['birthYear'];
        selectedRegion = data['region'];
      });
    }
  }

  Future<void> pickProfileImage() async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.front,
    );

    if (picked != null) {
      setState(() {
        profileImage = picked;
      });
    }
  }

  Future<void> updateUserInfo() async {
    print("✅ 수정 버튼 눌림");

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("비밀번호가 일치하지 않습니다.")),
      );
      return;
    }
    print("hi");
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    if (token == null) return;
    print("*");
    try {
      print("*");
      final formData = FormData.fromMap({
        "name": nicknameController.text,
        "password": passwordController.text,
        "birthYear": selectedBirthYear,
        "preferSports": selectedSport,
        "region": selectedRegion,
        if (profileImage != null)
          "profile": await MultipartFile.fromFile(
            profileImage!.path,
            filename: profileImage!.name,
          ),
      });
      print("*");

      final dio = Dio();
      final response = await dio.patch(
        "${ApiConstants.baseUrl}/users/update",
        data: formData,
        options: Options(headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "multipart/form-data",
        }),
      );

      print("응답 코드: ${response.statusCode}");
      print("🟢 서버 응답 내용: ${response.data}");

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("회원정보가 수정되었습니다.")),
        );
        Navigator.pop(context,true);
      } else {
        print("❌ 서버 응답 에러: ${response.data}");
      }
    } catch (e) {
      print("❗ 수정 실패: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("내 정보 수정")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickProfileImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: profileImage != null
                    ? FileImage(File(profileImage!.path))
                    : null,
                child: profileImage == null
                    ? const Icon(Icons.person, size: 50, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField("닉네임", nicknameController),
            _buildTextField("비밀번호", passwordController, obscure: true),
            _buildTextField("비밀번호 확인", confirmPasswordController, obscure: true),
            _buildDropdown("선호 종목", selectedSport, sports, (val) => setState(() => selectedSport = val)),
            _buildDropdown("출생년도", selectedBirthYear, years, (val) => setState(() => selectedBirthYear = val)),
            _buildDropdown("지역", selectedRegion, regions, (val) => setState(() => selectedRegion = val)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: updateUserInfo,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text("수정하기"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
