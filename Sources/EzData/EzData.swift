//
//  Data.swift
//  EzData
//
//  Created by Riccardo Terlizzi on 29/12/22.
//

import Foundation

@available(macOS 10.15, *)
open class EzData<T: Codable>: ObservableObject {
	public init() {
	}
	
	private static var documentsFolder: URL? {
		do {
			return try FileManager.default.url(
				for: .documentDirectory,
				in: .userDomainMask,
				appropriateFor: nil,
				create: false
			)
		} catch {
			return nil
		}
	}
	
	private static var fileURL: URL? {
		return documentsFolder?.appendingPathComponent("items.data") ?? nil
	}
	
	@Published open var items: [T] = []
	
	open func load() throws {
		if Self.fileURL == nil {
			throw LoadError.fileURLNotFound
		}
		
		var failed = false
		
		DispatchQueue.global(qos: .background).async { [weak self] in
			guard let data = try? Data(contentsOf: Self.fileURL!) else {
				return
			}
			
			guard let itemsData = try? JSONDecoder().decode([T].self, from: data) else {
				failed = true
				return
			}
			
			DispatchQueue.main.async { self?.items = itemsData }
		}
		
		if failed {
			throw LoadError.decodingError
		}
	}
	
	open func save() {
		if Self.fileURL == nil {
			return
		}
		
		DispatchQueue.global(qos: .background).async { [weak self] in
			guard let items = self?.items else {
				return
			}
			
			guard let data = try? JSONEncoder().encode(items) else {
				return
			}
			
			do {
				try data.write(to: Self.fileURL!)
			} catch {
				return
			}
		}
	}
}
