import 'package:flutter/material.dart';
import 'package:uber_app/screens/home/support_screen.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final List<FAQItem> _faqItems = [
    FAQItem(
      question: "How do I book a truck for delivery?",
      answer:
          "Simply open the app, enter your pickup and delivery locations, select the truck type you need, and confirm your booking. You'll be matched with available truck drivers in your area.",
      isExpanded: false,
    ),
    FAQItem(
      question: "What types of trucks are available?",
      answer:
          "We offer various truck types including pickup trucks, box trucks, flatbeds, refrigerated trucks, and heavy-duty trucks for different cargo needs.",
      isExpanded: false,
    ),
    FAQItem(
      question: "How is the pricing calculated?",
      answer:
          "Pricing is based on distance, truck type, cargo weight, and demand. You'll see an estimated price before confirming your booking.",
      isExpanded: false,
    ),
    FAQItem(
      question: "Can I track my delivery in real-time?",
      answer:
          "Yes! Once your booking is confirmed, you can track your delivery in real-time through our app with live GPS tracking.",
      isExpanded: false,
    ),
    FAQItem(
      question: "What payment methods are accepted?",
      answer:
          "We accept credit/debit cards, digital wallets, and in some regions, cash payments. All in-app payments are secure and encrypted.",
      isExpanded: false,
    ),
    FAQItem(
      question: "How do I cancel or reschedule a booking?",
      answer:
          "You can cancel or reschedule through the 'My Bookings' section. Cancellation fees may apply depending on timing.",
      isExpanded: false,
    ),
    FAQItem(
      question: "What if my goods get damaged during transit?",
      answer:
          "All our drivers are insured. In case of damage, report immediately through the app and our support team will assist with the claims process.",
      isExpanded: false,
    ),
    FAQItem(
      question: "How do I become a truck driver partner?",
      answer:
          "Visit our 'Drive with Us' section in the app or website to register. You'll need a valid driver's license, truck documents, and insurance.",
      isExpanded: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'FAQs',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Colors.transparent,
                ),
              ),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFFF6B35),
                      const Color(0xFFFF8B35),
                      const Color(0xFFFFA726),
                    ],
                  ),
                ),
                child: const Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Frequently Asked Questions',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Find answers to common questions',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search FAQs...',
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFFFF6B35),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    // const SizedBox(height: 20),
                    // // Categories
                    // SizedBox(
                    //   height: 100,
                    //   child: ListView(
                    //     scrollDirection: Axis.horizontal,
                    //     children: [
                    //       _buildCategoryItem(
                    //         Icons.local_shipping,
                    //         'Booking',
                    //         const Color(0xFFFF6B35),
                    //       ),
                    //       _buildCategoryItem(
                    //         Icons.attach_money,
                    //         'Pricing',
                    //         const Color(0xFFFF8B35),
                    //       ),
                    //       _buildCategoryItem(
                    //         Icons.security,
                    //         'Safety',
                    //         const Color(0xFFFFA726),
                    //       ),
                    //       _buildCategoryItem(
                    //         Icons.payment,
                    //         'Payments',
                    //         const Color(0xFFFFB74D),
                    //       ),
                    //       _buildCategoryItem(
                    //         Icons.assignment,
                    //         'Policies',
                    //         const Color(0xFFFFCC80),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                   
                   
                   
                    const SizedBox(height: 30),
                    // FAQ List
                    ..._faqItems.map((faq) => _buildFAQCard(faq)).toList(),
                    const SizedBox(height: 20),
                    // Contact CTA
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFFFF6B35).withOpacity(0.9),
                            const Color(0xFFFFA726),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.help_outline,
                            color: Colors.white,
                            size: 40,
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Still need help?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Contact our support team for further assistance',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>  SupportScreen(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(IconData icon, String label, Color color) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[800],
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQCard(FAQItem faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        title: Text(
          faq.question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        trailing: Icon(
          faq.isExpanded ? Icons.remove : Icons.add,
          color: const Color(0xFFFF6B35),
        ),
        childrenPadding:
            const EdgeInsets.only(left: 20, right: 20, bottom: 20),
        children: [
          Text(
            faq.answer,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
        onExpansionChanged: (expanded) {
          setState(() {
            faq.isExpanded = expanded;
          });
        },
      ),
    );
  }
}