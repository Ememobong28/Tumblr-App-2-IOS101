//
//  ViewController.swift
//  ios101-project6-tumblr
//

import UIKit
import Nuke

class ViewController: UIViewController, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var posts: [Post] = []
    private var offset: Int = 0
    private let limit: Int = 20
    
    private let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        
        if #available(iOS 10.0, *) {
               tableView.refreshControl = refreshControl
           } else {
               tableView.addSubview(refreshControl)
           }

           refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
           
        
        fetchPosts()
        
    }
    
    @objc private func refreshData(_ sender: Any) {
        print("🔄 Starting to refresh data...")
        offset += limit
        
        refreshControl.beginRefreshing()
        fetchPosts()
    }

    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let selectedIndexPath = tableView.indexPathForSelectedRow else {return}
        
        let selectedPost = posts[selectedIndexPath.row]
        
        guard let detailviewController = segue.destination as? DetailViewController else {return}
        
        detailviewController.post = selectedPost
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as! PostCell
        
        let post = posts[indexPath.row]
        
        cell.summaryLabel.text = post.summary
        
        if let photo = post.photos.first {
            let url = photo.originalSize.url
            Nuke.loadImage(with: url, into: cell.postImageView)
        }
        
        return cell
    }
    
    func fetchPosts() {
        let url = URL(string: "https://api.tumblr.com/v2/blog/nationalgeographicmagazine.tumblr.com/posts/photo?api_key=1zT8CiXGXFcQDyMFG7RtcfGLwTdDjFUJnZzKJaWTmgyK4lKGYk&limit=\(limit)&offset=\(offset)")!
        let session = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ Error: \(error.localizedDescription)")
                return
            }

            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, (200...299).contains(statusCode) else {
                print("❌ Response error: \(String(describing: response))")
                return
            }

            guard let data = data else {
                print("❌ Data is NIL")
                return
            }

            do {
                let blog = try JSONDecoder().decode(Blog.self, from: data)

                DispatchQueue.main.async { [weak self] in

                    let posts = blog.response.posts
                    let newPosts = blog.response.posts
                    self?.posts = posts
                    self?.posts.append(contentsOf: newPosts)
                    self?.posts.shuffle()
                    self?.tableView.reloadData()
                    self?.refreshControl.endRefreshing()
                    
                    

                    print("✅ We got \(posts.count) posts!")
                    for post in posts {
                        print("🍏 Summary: \(post.summary)")
                    }
                }

            } catch {
                print("❌ Error decoding JSON: \(error.localizedDescription)")
            }
        }
        session.resume()
    }
}
